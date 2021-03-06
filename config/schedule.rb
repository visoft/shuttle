# Copyright 2014 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

set :output, 'log/whenever.log'

every 30.minutes, roles: [:primary_cron] do
  runner 'AutoImporter.perform_once'
end

every 5.minutes, roles: [:primary_cron] do
  runner 'SidekiqWorkerRestarter.perform_once'
end

every :day, at: '12:00 am', roles: [:primary_cron] do
  runner 'InactiveUserDecommissioner.perform_once'
end

every :day, at: '12:00 am', roles: [:primary_cron] do
  rake 'metrics:update'
end

every 5.minute, roles: [:primary_cron] do
  rake 'touchdown:update'
end

every 1.hour, roles: [:primary_cron] do
  rake 'maintenance:cleanup_commits'
end

every :day, at: '1am', roles: [:app] do
  rake 'maintenance:cleanup_repos'
end

every :day, roles: [:primary_cron] do
  rake 'maintenance:reap_deleted_commits'
end

every :day, at: '2am', roles: [:app] do
  rake 'reports:generate:incoming'
end

every :day, at: '3am', roles: [:app] do
  rake 'reports:generate:pending'
end

every :day, at: '4am', roles: [:app] do
  rake 'reports:generate:completed'
end
