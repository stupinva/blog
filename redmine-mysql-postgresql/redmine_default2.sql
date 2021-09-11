ALTER TABLE ONLY attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY auth_sources
    ADD CONSTRAINT auth_sources_pkey PRIMARY KEY (id);
ALTER TABLE ONLY boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);
ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (id);
ALTER TABLE ONLY custom_values
    ADD CONSTRAINT custom_values_pkey PRIMARY KEY (id);
ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY enabled_modules
    ADD CONSTRAINT enabled_modules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY enumerations
    ADD CONSTRAINT enumerations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issue_categories
    ADD CONSTRAINT issue_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issue_relations
    ADD CONSTRAINT issue_relations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issue_statuses
    ADD CONSTRAINT issue_statuses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY journal_details
    ADD CONSTRAINT journal_details_pkey PRIMARY KEY (id);
ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (id);
ALTER TABLE ONLY member_roles
    ADD CONSTRAINT member_roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);
ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);
ALTER TABLE ONLY open_id_authentication_associations
    ADD CONSTRAINT open_id_authentication_associations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY open_id_authentication_nonces
    ADD CONSTRAINT open_id_authentication_nonces_pkey PRIMARY KEY (id);
ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY queries
    ADD CONSTRAINT queries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY time_entries
    ADD CONSTRAINT time_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY watchers
    ADD CONSTRAINT watchers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY wiki_content_versions
    ADD CONSTRAINT wiki_content_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY wiki_contents
    ADD CONSTRAINT wiki_contents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT wiki_pages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY wiki_redirects
    ADD CONSTRAINT wiki_redirects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY wikis
    ADD CONSTRAINT wikis_pkey PRIMARY KEY (id);
ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);
CREATE INDEX boards_project_id ON boards USING btree (project_id);
CREATE INDEX changeset_parents_changeset_ids ON changeset_parents USING btree (changeset_id);
CREATE INDEX changeset_parents_parent_ids ON changeset_parents USING btree (parent_id);
CREATE INDEX changesets_changeset_id ON changes USING btree (changeset_id);
CREATE UNIQUE INDEX changesets_issues_ids ON changesets_issues USING btree (changeset_id, issue_id);
CREATE UNIQUE INDEX changesets_repos_rev ON changesets USING btree (repository_id, revision);
CREATE INDEX changesets_repos_scmid ON changesets USING btree (repository_id, scmid);
CREATE UNIQUE INDEX custom_fields_roles_ids ON custom_fields_roles USING btree (custom_field_id, role_id);
CREATE INDEX custom_values_customized ON custom_values USING btree (customized_type, customized_id);
CREATE INDEX documents_project_id ON documents USING btree (project_id);
CREATE INDEX enabled_modules_project_id ON enabled_modules USING btree (project_id);
CREATE UNIQUE INDEX groups_users_ids ON groups_users USING btree (group_id, user_id);
CREATE INDEX index_attachments_on_author_id ON attachments USING btree (author_id);
CREATE INDEX index_attachments_on_container_id_and_container_type ON attachments USING btree (container_id, container_type);
CREATE INDEX index_attachments_on_created_on ON attachments USING btree (created_on);
CREATE INDEX index_auth_sources_on_id_and_type ON auth_sources USING btree (id, type);
CREATE INDEX index_boards_on_last_message_id ON boards USING btree (last_message_id);
CREATE INDEX index_changesets_on_committed_on ON changesets USING btree (committed_on);
CREATE INDEX index_changesets_on_repository_id ON changesets USING btree (repository_id);
CREATE INDEX index_changesets_on_user_id ON changesets USING btree (user_id);
CREATE INDEX index_comments_on_author_id ON comments USING btree (author_id);
CREATE INDEX index_comments_on_commented_id_and_commented_type ON comments USING btree (commented_id, commented_type);
CREATE INDEX index_custom_fields_on_id_and_type ON custom_fields USING btree (id, type);
CREATE UNIQUE INDEX index_custom_fields_projects_on_custom_field_id_and_project_id ON custom_fields_projects USING btree (custom_field_id, project_id);
CREATE UNIQUE INDEX index_custom_fields_trackers_on_custom_field_id_and_tracker_id ON custom_fields_trackers USING btree (custom_field_id, tracker_id);
CREATE INDEX index_custom_values_on_custom_field_id ON custom_values USING btree (custom_field_id);
CREATE INDEX index_documents_on_category_id ON documents USING btree (category_id);
CREATE INDEX index_documents_on_created_on ON documents USING btree (created_on);
CREATE INDEX index_enumerations_on_id_and_type ON enumerations USING btree (id, type);
CREATE INDEX index_enumerations_on_project_id ON enumerations USING btree (project_id);
CREATE INDEX index_issue_categories_on_assigned_to_id ON issue_categories USING btree (assigned_to_id);
CREATE INDEX index_issue_relations_on_issue_from_id ON issue_relations USING btree (issue_from_id);
CREATE UNIQUE INDEX index_issue_relations_on_issue_from_id_and_issue_to_id ON issue_relations USING btree (issue_from_id, issue_to_id);
CREATE INDEX index_issue_relations_on_issue_to_id ON issue_relations USING btree (issue_to_id);
CREATE INDEX index_issue_statuses_on_is_closed ON issue_statuses USING btree (is_closed);
CREATE INDEX index_issue_statuses_on_is_default ON issue_statuses USING btree (is_default);
CREATE INDEX index_issue_statuses_on_position ON issue_statuses USING btree (position);
CREATE INDEX index_issues_on_assigned_to_id ON issues USING btree (assigned_to_id);
CREATE INDEX index_issues_on_author_id ON issues USING btree (author_id);
CREATE INDEX index_issues_on_category_id ON issues USING btree (category_id);
CREATE INDEX index_issues_on_created_on ON issues USING btree (created_on);
CREATE INDEX index_issues_on_fixed_version_id ON issues USING btree (fixed_version_id);
CREATE INDEX index_issues_on_priority_id ON issues USING btree (priority_id);
CREATE INDEX index_issues_on_root_id_and_lft_and_rgt ON issues USING btree (root_id, lft, rgt);
CREATE INDEX index_issues_on_status_id ON issues USING btree (status_id);
CREATE INDEX index_issues_on_tracker_id ON issues USING btree (tracker_id);
CREATE INDEX index_journals_on_created_on ON journals USING btree (created_on);
CREATE INDEX index_journals_on_journalized_id ON journals USING btree (journalized_id);
CREATE INDEX index_journals_on_user_id ON journals USING btree (user_id);
CREATE INDEX index_member_roles_on_member_id ON member_roles USING btree (member_id);
CREATE INDEX index_member_roles_on_role_id ON member_roles USING btree (role_id);
CREATE INDEX index_members_on_project_id ON members USING btree (project_id);
CREATE INDEX index_members_on_user_id ON members USING btree (user_id);
CREATE UNIQUE INDEX index_members_on_user_id_and_project_id ON members USING btree (user_id, project_id);
CREATE INDEX index_messages_on_author_id ON messages USING btree (author_id);
CREATE INDEX index_messages_on_created_on ON messages USING btree (created_on);
CREATE INDEX index_messages_on_last_reply_id ON messages USING btree (last_reply_id);
CREATE INDEX index_news_on_author_id ON news USING btree (author_id);
CREATE INDEX index_news_on_created_on ON news USING btree (created_on);
CREATE INDEX index_projects_on_lft ON projects USING btree (lft);
CREATE INDEX index_projects_on_rgt ON projects USING btree (rgt);
CREATE INDEX index_queries_on_project_id ON queries USING btree (project_id);
CREATE INDEX index_queries_on_user_id ON queries USING btree (user_id);
CREATE INDEX index_repositories_on_project_id ON repositories USING btree (project_id);
CREATE INDEX index_settings_on_name ON settings USING btree (name);
CREATE INDEX index_time_entries_on_activity_id ON time_entries USING btree (activity_id);
CREATE INDEX index_time_entries_on_created_on ON time_entries USING btree (created_on);
CREATE INDEX index_time_entries_on_user_id ON time_entries USING btree (user_id);
CREATE INDEX index_tokens_on_user_id ON tokens USING btree (user_id);
CREATE INDEX index_user_preferences_on_user_id ON user_preferences USING btree (user_id);
CREATE INDEX index_users_on_auth_source_id ON users USING btree (auth_source_id);
CREATE INDEX index_users_on_id_and_type ON users USING btree (id, type);
CREATE INDEX index_users_on_type ON users USING btree (type);
CREATE INDEX index_versions_on_sharing ON versions USING btree (sharing);
CREATE INDEX index_watchers_on_user_id ON watchers USING btree (user_id);
CREATE INDEX index_watchers_on_watchable_id_and_watchable_type ON watchers USING btree (watchable_id, watchable_type);
CREATE INDEX index_wiki_content_versions_on_updated_on ON wiki_content_versions USING btree (updated_on);
CREATE INDEX index_wiki_contents_on_author_id ON wiki_contents USING btree (author_id);
CREATE INDEX index_wiki_pages_on_parent_id ON wiki_pages USING btree (parent_id);
CREATE INDEX index_wiki_pages_on_wiki_id ON wiki_pages USING btree (wiki_id);
CREATE INDEX index_wiki_redirects_on_wiki_id ON wiki_redirects USING btree (wiki_id);
CREATE INDEX index_workflows_on_new_status_id ON workflows USING btree (new_status_id);
CREATE INDEX index_workflows_on_old_status_id ON workflows USING btree (old_status_id);
CREATE INDEX index_workflows_on_role_id ON workflows USING btree (role_id);
CREATE INDEX issue_categories_project_id ON issue_categories USING btree (project_id);
CREATE INDEX issues_project_id ON issues USING btree (project_id);
CREATE INDEX journal_details_journal_id ON journal_details USING btree (journal_id);
CREATE INDEX journals_journalized_id ON journals USING btree (journalized_id, journalized_type);
CREATE INDEX messages_board_id ON messages USING btree (board_id);
CREATE INDEX messages_parent_id ON messages USING btree (parent_id);
CREATE INDEX news_project_id ON news USING btree (project_id);
CREATE INDEX projects_trackers_project_id ON projects_trackers USING btree (project_id);
CREATE UNIQUE INDEX projects_trackers_unique ON projects_trackers USING btree (project_id, tracker_id);
CREATE UNIQUE INDEX queries_roles_ids ON queries_roles USING btree (query_id, role_id);
CREATE INDEX time_entries_issue_id ON time_entries USING btree (issue_id);
CREATE INDEX time_entries_project_id ON time_entries USING btree (project_id);
CREATE UNIQUE INDEX tokens_value ON tokens USING btree (value);
CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);
CREATE INDEX versions_project_id ON versions USING btree (project_id);
CREATE INDEX watchers_user_id_type ON watchers USING btree (user_id, watchable_type);
CREATE INDEX wiki_content_versions_wcid ON wiki_content_versions USING btree (wiki_content_id);
CREATE INDEX wiki_contents_page_id ON wiki_contents USING btree (page_id);
CREATE INDEX wiki_pages_wiki_id_title ON wiki_pages USING btree (wiki_id, title);
CREATE INDEX wiki_redirects_wiki_id_title ON wiki_redirects USING btree (wiki_id, title);
CREATE INDEX wikis_project_id ON wikis USING btree (project_id);
CREATE INDEX wkfs_role_tracker_old_status ON workflows USING btree (role_id, tracker_id, old_status_id);
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;

