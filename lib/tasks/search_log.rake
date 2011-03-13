namespace :search_log do
  desc "update search_log language"
  task :update_lang => :environment do
    counter = 0
    detector = LanguageDetector.new
    
    SearchLog.find_in_batches do |slogs|
      slogs.each do |slog|
        if slog.lang.nil?
          if ['google', 'facebook', 'test', 'hello' , 'sex', 'porn', 'google sloppy', 'apple'].include? slog.query
            slog.lang = 'en'
          else
            slog.lang = GLanguageDetector.detect(slog.query)
          end
          slog.save
          puts "== ID: #{slog.id}, Query: #{slog.query}, Lang: #{slog.lang}"
          #counter += 1
          #if counter > 10
          #  puts "Sleep"
          #  sleep(1)
          #  counter = 0
          #end
        else
          puts "skipped"
        end
      end
    end
  end
end