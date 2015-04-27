module Pancakes
  module Fleet
    class Cluster
      attr_reader :client
      attr_writer :dry_run

      def initialize(dry_run: false)
        @dry_run = dry_run
        if @dry_run
          logger.warn "fleet cluster dry_run=true"
        end
        @client ||= ::Fleet.new(read_timeout: 10, open_timeout: 10)
      end

      # @api private
      def logger
        return @__lgr if @__lgr
        #Logging.logger[self].appenders = Pancakes.log_appender
        #Logging.logger[self].level = Pancakes.log_level
        @__lgr = Logging.logger[self]
      end

      def dry_run?
        @dry_run
      end

      def start_unit(unit)
        unit_fname = Templating.gen_service_file_name(unit)
        unit_hash  = Templating.detect_and_make_template(unit)

        if !@dry_run
          logger.debug "submitting #{unit_fname}"
          @client.submit(unit_fname, unit_hash)

          sleep 0.1

          logger.debug "loading #{unit_fname}"
          @client.load(unit_fname)

          sleep 0.1

          logger.info "starting #{unit_fname}"
          @client.start(unit_fname)

          sleep 0.1
        else
          logger.info "dry-run starting #{unit_fname}"
          logger.debug "\n" + unit_hash.ai
        end
      rescue ::Fleet::Conflict => e
        raise Pancakes::ClusterError.new_with_original(e)
      end

      def destroy_unit(unit)
        unit_fname = Templating.gen_service_file_name(unit)

        if !@dry_run
          logger.info "destroying #{unit_fname}"
          @client.destroy(unit_fname)
          sleep 0.3
        else
          logger.info "dry-run destroying #{unit_fname}"
        end
      rescue ::Fleet::NotFound => e
        logger.info "unit #{unit.name} not found during destroy. that's fine, we want it gone"
      end

      # @api private
      def reset_failed(host)
        if !@dry_run
          logger.info "calling systemctl reset-failed on #{host}"
          system("ssh core@#{host} sudo systemctl reset-failed")
          StatHatWrapper.post_count('pancakes fleet cluster reset-failed calls', 1)
        else
          logger.info "dry_run calling but not really systemctl reset-failed on #{host}"
        end
      end

      def reset_failed_all
        worker_machine_ips.each do |ip|
          reset_failed(ip)
        end
      end

      # @api private
      def worker_machine_ips
        list_machines.select{|m| m['metadata']['role'] == 'worker' }.map{|m| m['primaryIP'] }
      end

      # @api private
      def list_machines
        logger.info 'getting all machines'
        @client.list_machines['machines']
      end

      def all_units
        logger.info 'getting all units'
        @client.list.select{|u| Unit.pancakes_unit?(u[:name]) }.map{|u| Hashie::Mash.new(u) }
      end
    end
  end
end
