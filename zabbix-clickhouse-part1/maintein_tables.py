#!/usr/bin/python
# -*- coding: UTF-8 -*-

from clickhouse_driver import Client
from datetime import datetime, timedelta

try:
    c = Client(host='localhost',
               port=9000,
               connect_timeout=3,
               database='zabbix',
               user='zabbix',
               password='zabbix')
except clickhouse_driver.errors.ServerException:
    print >>sys.stderr, 'Cannot connect to database'
    sys.exit(1)
  
def maintein_table(c, database, table, keep_interval):
    """
    Удаление устаревших разделов указанной таблицы и оптимизация оставшихся разделов
    
    c - подключение к базе данных 
    database - имя базы данных, в которой нужно произвести усечение таблицы
    table - имя таблицы, которую нужно усечь
    keep_interval - период, данные за который нужно сохранить, тип - timedelta
    """
    now = datetime.now()

    rows = c.execute('''SELECT partition,
                               COUNT(*)
                        FROM system.parts
                        WHERE database = '%s'
                          AND table = '%s'
                        GROUP BY partition
                        ORDER BY partition
                     ''' % (database, table))
    for partition, num in rows:
        if now - datetime.strptime(partition, '%Y%m%d') > keep_interval:
            print 'drop partition %s %s %s' % (database, table, partition)
            c.execute('ALTER TABLE %s.%s DROP PARTITION %s' % (database, table, partition))
        elif num > 1:
            print 'optimize partition %s %s %s' % (database, table, partition)
            c.execute('OPTIMIZE TABLE %s.%s PARTITION %s FINAL DEDUPLICATE' % (database, table, partition))

maintein_table(c, 'zabbix', 'trends', timedelta(days=3650))
maintein_table(c, 'zabbix', 'trends_uint', timedelta(days=3650))
maintein_table(c, 'zabbix', 'real_history', timedelta(days=365))
maintein_table(c, 'zabbix', 'real_history_uint', timedelta(days=365))
maintein_table(c, 'zabbix', 'real_history_str', timedelta(days=7))
maintein_table(c, 'zabbix', 'real_history_text', timedelta(days=7))
maintein_table(c, 'zabbix', 'real_history_log', timedelta(days=7))
c.disconnect()
