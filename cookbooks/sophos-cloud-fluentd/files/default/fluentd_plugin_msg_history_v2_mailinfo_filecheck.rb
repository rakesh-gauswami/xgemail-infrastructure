require 'fluent/plugin/filter'

module Fluent::Plugin
  class MailInfoFileCheckFilter < Filter
    # Register this filter as "mhv2filecheck"
    Fluent::Plugin.register_filter('mhv2filecheck', self)

    config_param :mh_mail_info_storage_dir, :string, :default => '/storage/msg-history/mh-mail-info'

    def configure(conf)
      super
    end

    def filter(tag, time, record)
      if (!record.key?('queue_id'))
        log.debug("key queue_id doesnt exist")
        return nil
      end

      mail_info_file_path = @mh_mail_info_storage_dir + '/' + record['queue_id']
      if(!File.exist?(mail_info_file_path))
        log.debug("mail info file path " + mail_info_file_path + " doesnt exist")
        return nil
      end

      record
    end
  end
end
