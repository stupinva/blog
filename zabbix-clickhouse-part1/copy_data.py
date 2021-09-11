#!/usr/bin/python
# -*- coding: UTF-8 -*-

# apt-get install python-clickhouse-driver python-enum34 python-ipaddress

import math, sys, psycopg2, MySQLdb, clickhouse_driver, _mysql_exceptions
from random import random, shuffle
from datetime import datetime

psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)
psycopg2.extensions.register_type(psycopg2.extensions.UNICODEARRAY)

databases = {
    'source': {
        'type': 'MySQL',
        'host': 'localhost',
        'port': 3306,
        'db': 'zabbix',
        'user': 'zabbix',
        'password': 'zabbix'
    },

    'destination': {
        'type': 'ClickHouse',
        'host': '127.0.0.1',
        'port': 9000,
        'db': 'zabbix',
        'user': 'zabbix',
        'password': 'zabbix'
    }
}

dbcache = {}

# Возвращает новый курсор указанной базы данных
def db(name='default'):
    # Если такой базы нет, нет курсора
    if name not in databases:
        return None

    # Если подключение к базе уже установлено
    if name in dbcache:
        cursor = dbcache[name].cursor()

        # И если оно ещё не оборвалось, то используем его
        try:
            cursor.execute('SELECT 1')
            return cursor
        except:
            pass

    base = databases[name]

    # Создаём подключение в зависимости от типа базы
    if base['type'] == 'MySQL':
        try:
            conn = MySQLdb.connect(host=base['host'],
                                   port=int(base['port']),
                                   connect_timeout=3,
                                   db=base['db'],
                                   charset='utf8',
                                   user=base['user'],
                                   passwd=base['password'])
        except _mysql_exceptions.OperationalError:
            print >>sys.stderr, u'Не удалось подключиться к базе данных %s' % name
            return None
        conn.autocommit(True)
        dbcache[name] = conn
        return conn.cursor()
    elif base['type'] == 'PostgreSQL':
        try:
            conn = psycopg2.connect(host=base['host'],
                                    port=int(base['port']),
                                    connect_timeout=3,
                                    database=base['db'],
                                    user=base['user'],
                                    password=base['password'])
        except psycopg2.OperationalError:
            print >>sys.stderr, u'Не удалось подключиться к базе данных %s' % name
            return None
        conn.autocommit = True
        dbcache[name] = conn
        return conn.cursor()
    elif base['type'] == 'ClickHouse':
        try:
            conn = clickhouse_driver.Client(host=base['host'],
                                            port=int(base['port']),
                                            connect_timeout=3,
                                            database=base['db'],
                                            user=base['user'],
                                            password=base['password'])
        except clickhouse_driver.errors.ServerException:
            print >>sys.stderr, u'Не удалось подключиться к базе данных %s' % name
            return None
        return conn

    return None

# Источник данных
# Извлекает строки из указанной таблицы за указанный диапазон времени с указанным шагом
class Source(object):
    def __init__(self, tablename, columns):
        self.cursor = db('source')
        self.tablename = tablename
        self.columns = columns

        # Получаем список идентификаторов актуальных элементов данных
        self.itemids = set()
        self.cursor.execute('''SELECT DISTINCT itemid
                               FROM items''')
        for itemid, in self.cursor:
            self.itemids.add(itemid)

        # Готовим запрос для извлечения данных
        cols = ', '.join(columns)
        self.query = '''SELECT %s
                        FROM %s
                        WHERE clock BETWEEN %%s AND %%s''' % (cols, self.tablename)

    # Узнаём временной диапазон копируемых данных
    def clock_min_max(self, clock_min, clock_max):
        if clock_min is not None and clock_max is not None:
            return clock_min, clock_max

        self.cursor.execute('''SELECT MIN(clock), MAX(clock)
                               FROM %s''' % self.tablename)
        row = self.cursor.fetchone()
        _clock_min, _clock_max = row
        if not _clock_min:
            raise ValueError('No data in table %s' % self.tablename)

        if clock_min is None:
            clock_min = _clock_min

        if clock_max is None:
            clock_max = _clock_max
        return clock_min, clock_max

    def select(self, clock_min, clock_max, step, int_mode=False):
        # Округляем границы временного диапазона до указанного шага
        clock_min = clock_min - clock_min % step

        rest = clock_max % step
        if rest:
            clock_max = clock_max - rest + step

        # Проходимся по временному диапазону с указанным шагом
        for clock in xrange(clock_min, clock_max, step):
            print 'select', self.tablename, datetime.fromtimestamp(clock), datetime.fromtimestamp(clock + step)
            self.cursor.execute(self.query, (clock, clock + step))

            for row in self.cursor:
                dict_row = dict(zip(self.columns, row))
                # Пропускаем удалённые элементы данных
                if 'itemid' in dict_row and dict_row['itemid'] not in self.itemids:
                    continue

                yield row

# Получатель данных - ClickHouse
# Аккумулирует полученные строки в буфере и вставляет их порциями указанного размера
class Destination(object):
    def __init__(self, tablename, columns, portion):
        self.cursor = db('destination')
        self.tablename = tablename
        self.portion = portion
        self.rows = []
        self.num = 0

        # Готовим запрос для вставки данных
        cols = ','.join(columns)
        self.query = 'INSERT INTO %s(%s) VALUES' % (self.tablename, cols)

    def insert_rows(self, rows):
        inserted = 0
        try:
            self.cursor.execute(self.query, rows)
            inserted = len(rows)
        except clickhouse_driver.errors.TypeMismatchError:
            n = len(rows)
            if n == 1:
                print 'wrong row: ', rows[0]
            else:
                i = n / 2
                inserted += self.insert_rows(rows[0:i])
                inserted += self.insert_rows(rows[i:n])
        return inserted

    def flush(self):
        if self.num:
            print 'insert', self.tablename, self.num
            inserted = self.insert_rows(self.rows)
            if self.num != inserted:
                print 'inserted', self.tablename, inserted
            self.rows = []
            self.num = 0

    def insert(self, row):
        self.rows.append(row)
        self.num += 1

        if self.num == self.portion:
            self.flush()

# Универсальная функция для копирования таблиц истории
def copy_history(tablename, columns, interval=86400, portion=1048576, clock_min=None, clock_max=None):
    source = Source(tablename, columns)
    try:
        clock_min, clock_max = source.clock_min_max(clock_min, clock_max)
    except ValueError:
        return None, None

    destination = Destination(tablename, columns, portion)

    for row in source.select(clock_min, clock_max, interval):
        destination.insert(row)
    destination.flush()
    return clock_min, clock_max

# Сравнение чисел с плавающей запятой
# Взято по ссылке https://stackoverflow.com/a/39347138
def isclose(a, b, rel_tol=1e-09, abs_tol=0.0):
    '''
    Python 2 implementation of Python 3.5 math.isclose()
    https://hg.python.org/cpython/file/tip/Modules/mathmodule.c#l1993
    '''
    # sanity check on the inputs
    if rel_tol < 0 or abs_tol < 0:
        raise ValueError("tolerances must be non-negative")

    # short circuit exact equality -- needed to catch two infinities of
    # the same sign. And perhaps speeds things up a bit sometimes.
    if a == b:
        return True

    # This catches the case of two infinities of opposite sign, or
    # one infinity and one finite number. Two infinities of opposite
    # sign would otherwise have an infinite relative tolerance.
    # Two infinities of the same sign are caught by the equality check
    # above.
    if math.isinf(a) or math.isinf(b):
        return False

    # now do the regular computation
    # this is essentially the "weak" test from the Boost library
    diff = math.fabs(b - a)
    result = (((diff <= math.fabs(rel_tol * b)) or
               (diff <= math.fabs(rel_tol * a))) or
              (diff <= abs_tol))
    return result

# Исключение, которое выбрасывается, если сгенерирована последовательность значений,
# не соответствюущая исходным данным из таблицы тенденций
class WrongSequence(ValueError):
    def __init__(self, message, seq_min, seq_avg, seq_max,
                                value_min, value_avg, value_max, num):
        self.message = message

        self.seq_min = seq_min
        self.seq_avg = seq_avg
        self.seq_max = seq_max

        self.value_min = value_min
        self.value_avg = value_avg
        self.value_max = value_max
        self.num = num

# Проверка соответствия последовательности значений исходным данным из таблицы тенденций
def check_sequence(value_min, value_max, value_avg, num, values, int_mode=False):
    # Проверяем исходные данные из таблицы тенденций
    if not isinstance(num, (int, long)):
        raise ValueError('num is not integer number')
    if num < 0:
        raise ValueError('num is negative number')
    if value_min > value_max:
        raise ValueError('value_min > value_max')
    if value_avg > value_max:
        raise ValueError('value_avg > value_max')
    if value_avg < value_min:
        raise ValueError('value_avg < value_min')
    if len(values) != num:
        raise ValueError('len(values) != num: %d != %d' % (len(values), num))

    # Считаем данные тенденций из последовательности значений
    seq_min = None
    seq_max = None
    seq_sum = 0
    values.sort()
    for value in values:
        if seq_min is None or value < seq_min:
            seq_min = value
        if seq_max is None or value > seq_max:
            seq_max = value
        seq_sum += value

    seq_avg = seq_sum / num

    # Сверяем исходные данные тенденций с данными тенденций, посчитанными из последовательности значений
    # При обнаружении несоответствия выбрасываем исключение
    if int_mode:
        if seq_min != value_min:
            raise WrongSequence('seq_min != value_min: %d != %d' % (seq_min, value_min),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)
        if seq_max != value_max:
            raise WrongSequence('seq_max != value_max: %d != %d' % (seq_max, value_max),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)
        if seq_avg != value_avg:
            raise WrongSequence('seq_avg != value_avg: %d != %d' % (seq_avg, value_avg),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)
    else:
        if not isclose(seq_min, value_min):
            raise WrongSequence('seq_min != value_min: %f != %f' % (seq_min, value_min),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)
        if not isclose(seq_max, value_max):
            raise WrongSequence('seq_max != value_max: %f != %f' % (seq_max, value_max),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)
        if not isclose(seq_avg, value_avg):
            raise WrongSequence('seq_avg != value_avg: %f != %f' % (seq_avg, value_avg),
                      seq_min, seq_avg, seq_max,
                      value_min, value_avg, value_max, num)

# Генерируем случайную последовательность чисел, удовлетворяющую исходным данным из таблицы тенденций
def generate_random_sequence(value_min, value_max, value_avg, num, int_mode=False):
    # Проверяем исходные данные из таблицы тенденций, по которым нужно сгенерировать последовательность
    if not isinstance(num, (int, long)):
        raise ValueError('num is not integer number')
    if num < 0:
        raise ValueError('num is negative number')
    if value_min > value_max:
        raise ValueError('value_min > value_max')
    if value_avg > value_max:
        raise ValueError('value_avg > value_max')
    if value_avg < value_min:
        raise ValueError('value_avg < value_min')

    # Если нужен пустой список, возвращаем его
    if num == 0:
        return []
    # Если нужен список из одного значения, возвращаем среднее
    elif num == 1:
        #if int_mode:
        #    if value_min != value_avg or value_avg != value_max:
        #        raise ValueError('value_min != value_avg != value_max')
        #else:
        #    if not isclose(value_min, value_avg) or not isclose(value_avg, value_max):
        #        raise ValueError('value_min != value_avg != value_max')
        return [value_avg]
    # Если нужен список из двух значений, возвращаем минимум и максимум
    elif num == 2:
        #if int_mode:
        #    if value_min + value_max != 2 * value_avg:
        #        raise ValueError('value_min + value_max != 2 * value_avg')
        #else:
        #    if not isclose(value_min + value_max, 2.0 * value_avg):
        #        raise ValueError('value_min + value_max != 2 * value_avg')
        return [value_min, value_max]

    # Добавляем в список минимальное и максимальное значения
    values = [value_min, value_max]

    # Исключаем минимум и максимум из оставшейся суммы и количества элементов последовательности
    value_sum = value_avg * num - value_min - value_max
    num -= 2

    # Пока осталось сгенерировать больше одного числа, выполняем генерацию
    while num > 1:
        # Расчитываем минимальное значение оставшейся последовательности двумя способами,
        # выбираем из них минимальное
        min1 = value_sum - value_max * (num - 1)
        min2 = (value_sum - value_max) / (num - 1)
        min0 = min(min1, min2)

        # Выполняем отсечку минимального значения оставшейся последовательности по заданным
        # минимуму и максимуму желаемой последовательности
        if min0 < value_min:
            min0 = value_min
        if min0 > value_max:
            min0 = value_max

        # Расчитываем максимальное значение оставшейся последовательности двумя способами,
        # выбираем из них максимальное
        max1 = value_sum - value_min * (num - 1)
        max2 = (value_sum - value_min) / (num - 1)
        max0 = max(max1, max2)

        # Выполняем отсечку максимального значения оставшейся последовательности по заданным
        # минимуму и максимуму желаемой последовательности
        if max0 < value_min:
            max0 = value_min
        if max0 > value_max:
            max0 = value_max

        # Генерируем случайное число в рамках минимума и максимума оставшейся последовательности
        value = (max0 - min0) * random() + min0

        # Если нужно целое число, выполняем округление
        if int_mode:
            value = long(value + 0.5)

        # Добавляем сгенерированное число к последовательности
        values.append(value)

        # Исключаем сгенерированное число из оставшейся суммы и количества элементов последовательности
        value_sum -= value
        num -= 1

    # Оставшаяся сумма будет являться последним элементом последовательности и должна находиться
    # между минимумом и максимумом желаемой последовательности
    # Если это не так, выполняем отсечку по минимуму и максимуму
    if value_sum > value_max:
        values.append(value_max)
    elif value_sum < value_min:
        values.append(value_min)
    else:
        values.append(value_sum)

    # Возвращаем сгенерированную последовательность
    return values

# Функция для пересчёта длительности из текстового формата с суффиксами в секунды
def delay_to_seconds(delay):
    try:
        delay, dummy = delay.split(';', 1)
    except ValueError:
        pass
    if delay[-1] == 's':
        return int(delay[:-1])
    elif delay[-1] == 'm':
        return int(delay[:-1]) * 60
    elif delay[-1] == 'h':
        return int(delay[:-1]) * 3600
    elif delay[-1] == 'd':
        return int(delay[:-1]) * 86400
    elif delay[-1] == 'w':
        return int(delay[:-1]) * 604800
    elif delay == '0':
        return 0
    raise ValueError('wrong delay')

# Генерация правдоподобной истории по данным тенденций
class Transform(object):
    def __init__(self, int_mode):
        self.int_mode = int_mode

        # Получаем список идентификаторов актуальных элементов данных и периода их обновления
        self.itemids = {}
        cursor = db('source')
        cursor.execute('''SELECT DISTINCT itemid, type, delay
                          FROM items''')
        for itemid, type, delay in cursor:
            if type in (2, 17): # Zabbix-trapper, SNMP trap
                self.itemids[itemid] = 0
            else:
                self.itemids[itemid] = delay_to_seconds(delay)

    def __call__(self, row):
        if self.int_mode:
            for key in ('value_min', 'value_max', 'value_avg'):
                row[key] = long(row[key])
        else:
            for key in ('value_min', 'value_max', 'value_avg'):
                row[key] = float(row[key])

        # Генерируем правдоподобную историю и проверяем её
        try:
            values = generate_random_sequence(row['value_min'], row['value_max'], row['value_avg'], row['num'], self.int_mode)
        except ValueError as e:
            # Исходные данные тенденций противоречат сами себе,
            # сгенерировать правдоподобную последовательность из них невозможно
            print 'SUSPICIOUS TREND', row['value_min'], row['value_avg'], row['value_max'], row['num']
            return []

        # Проверяем соответствие сгенерированной последовательности исходным данным тенденций
        try:
            check_sequence(row['value_min'], row['value_max'], row['value_avg'], row['num'], values, self.int_mode)
        except ValueError as e:
            # По идее, это исключение поймать здесь уже невозможно, т.к. ранее такая проврека уже делалась в generate_random_sequence
            # Исходные данные тенденций противоречат сами себе,
            # сгенерировать правдоподобную последовательность из них невозможно,
            # поэтому последовательность не проверяем
            print 'SUSPICIOUS TREND', row['value_min'], row['value_avg'], row['value_max'], row['num']
        except WrongSequence as e:
            # Сгенерирована последовательность, не удовлетворяющая исходным данным тенденций
            # Выводим предупреждение, но сгенерированные значения принимаем
            print 'suspicious trend', e.seq_min, e.seq_avg, e.seq_max, e.num, \
                                      e.value_min, e.value_avg, e.value_max

        # Выясняем, с каким интервалом можно расставить сгенерированные значения в рамках часа
        if 'itemid' in row and row['itemid'] in self.itemids and self.itemids[row['itemid']] > 0:
           delay = self.itemids[row['itemid']]
           max_num = 3600.0 / delay
        else:
           delay = 3600.0 / row['num']
           max_num = row['num']

        # Генерируем моменты времени внутри часа
        clocks = []
        clock = row['clock']
        while clock < row['clock'] + 3600.0:
            int_clock = int(clock)
            ns = int((clock - int_clock) * 1000000000.0)
            clocks.append((clock, ns))

            clock += delay
            
        # Перемешиваем значения из сгенерированной выборки и моменты времени случайным образом
        shuffle(values)
        shuffle(clocks)

        # Формируем строки истории, соединяя значения и соответствующие им моменты времени
        rows = []
        for value, clock_ns in zip(values, clocks):
            clock, ns = clock_ns
            rows.append((row['itemid'], clock, ns, value))
        return rows

# Функция для копирования таблиц тенденций в таблицы истории
def copy_trends(source_table, destination_table, interval=86400, portion=1048576, clock_min=None, clock_max=None, int_mode=False):
    source_columns = ('itemid', 'clock', 'num', 'value_min', 'value_avg', 'value_max')
    source = Source(source_table, source_columns)
    try:
        clock_min, clock_max = source.clock_min_max(clock_min, clock_max)
    except ValueError:
        return None, None

    destination = Destination(destination_table, ('itemid', 'clock', 'ns', 'value'), portion)

    transform = Transform(int_mode)

    for trend_row in source.select(clock_min, clock_max, interval):
        dict_row = dict(zip(source_columns, trend_row))
        pseudohistory_rows = transform(dict_row)
        for pseudohistory_row in pseudohistory_rows:
            destination.insert(pseudohistory_row)
    destination.flush()
    return clock_min, clock_max

if __name__ == '__main__':
    copy_history('history_str', ('itemid', 'clock', 'ns', 'value'))
    copy_history('history_text', ('itemid', 'clock', 'ns', 'value'))
    copy_history('history_log', ('itemid', 'clock', 'timestamp', 'source', 'severity', 'value', 'logeventid', 'ns'))

    clock_min, clock_max = copy_history('history', ('itemid', 'clock', 'ns', 'value'), interval=10800)
    copy_trends('trends', 'history', clock_max=clock_min)

    clock_min, clock_max = copy_history('history_uint', ('itemid', 'clock', 'ns', 'value'), interval=1800)
    copy_trends('trends_uint', 'history_uint', clock_max=clock_max, int_mode=True)
