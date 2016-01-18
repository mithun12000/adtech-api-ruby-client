import 'java.util.Calendar'
import 'java.util.GregorianCalendar'

module ADTech
  module API
    class Report

      def client
        @client ||= ADTech::Client.new.helios
      end

      def gregoian_calendar(year, month, day, hour, minute, second)
        cal = GregorianCalendar.getInstance()
        cal.set(Calendar::DAY_OF_MONTH, day)
		    cal.set(Calendar::MONTH, month)
		    cal.set(Calendar::YEAR, year)
		    cal.set(Calendar::HOUR, hour)
		    cal.set(Calendar::MINUTE, minute)
		    cal.set(Calendar::SECOND, second)
        cal
      end

      def get_report_url(report_type_id, start_date, end_date, entities)
        report = client.reportService.getReportById(report_type_id)

        ADTech.logger.info "Your report (#{report_type_id}) is of entity type: #{report.getEntityType} "
             "and report category: #{report.getReportCategory()}"

        start_cal = gregoian_calendar(start_date.year,
                                      start_date.month - 1,
                                      start_date.day,
                                      0,
                                      0,
                                      0)
        ADTech.logger.info "Report start date set to: #{start_cal.getTime}";

        end_cal = gregoian_calendar(end_date.year,
                                    end_date.month - 1,
                                    end_date.day,
                                    23,
                                    59,
                                    59)
        ADTech.logger.info "Report end date set to: #{end_cal.getTime}";

        report_queue_entry = client.reportService.requestReportByEntities(
          report_type_id,
          start_cal.getTime,
          end_cal.getTime,
          IReport::REPORT_ENTITY_TYPE_NETWORK,
          IReport::REPORT_CATEGORY_WEBSITE,
          entities
        )

        report_download_url('report',
                            System.getProperty("line.separator"),
                            'csv',
                            report_queue_entry)
      end

      def report_download_url(file_name, line_sep, extension, report_queue_entry)
        ADTech.logger.info 'Start polling for report...'
        report_url = ''

        while (true)
          report_queue_entry = client.reportService.getReportQueueEntryById(report_queue_entry.getId())

          status = ''
          case report_queue_entry.getState()
          when IReportQueueEntry::STATE_ENTERED
            status = 'ENTERED'
          when IReportQueueEntry::STATE_BUSY
            status = 'BUSY'
          when IReportQueueEntry::STATE_FINISHED
            status = 'FINISHED'
          when IReportQueueEntry::STATE_DELETED
            status = 'DELETED'
          when IReportQueueEntry::STATE_FAILED
            status = 'FAILED'
          end

          if report_queue_entry.getState() == IReportQueueEntry::STATE_DELETED ||
            report_queue_entry.getState() == IReportQueueEntry::STATE_FAILED
            ADTech.logger.error "Report state is: #{status}"
            ADTech.logger.info 'Exiting...'
            break
          elsif report_queue_entry.getState() == IReportQueueEntry::STATE_FINISHED
            ADTech.logger.info "Report state: #{status}"
            report_url = "#{report_queue_entry.getResultURL()}&format=#{extension}"
            ADTech.logger.info "ResultURL: '#{report_url}'"
            break
          end

          sleep(10)
        end

        report_url
      end
    end
  end
end