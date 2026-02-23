require 'sidekiq'
require 'sidekiq-cron'

# Sidekiq configuration
Sidekiq.configure_server do |config|
  # Load scheduled jobs from YAML file
  schedule_file = Rails.root.join('config', 'schedule.yml')
  
  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    
    # Load schedule for current environment
    if schedule[Rails.env]
      Sidekiq::Cron::Job.load_from_hash(schedule[Rails.env])
      Rails.logger.info "✅ Loaded #{schedule[Rails.env].keys.count} scheduled job(s) for #{Rails.env} environment"
    end
  end
end
