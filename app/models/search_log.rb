class SearchLog < ActiveRecord::Base
  APP_LAUNCH_DATE = "2011-03-03".to_date
  
  before_create :set_lang
  
  scope :created_at_this_date, lambda { |d| where(:created_at => (d)..(d+1.day)) }
  
  def self.find_messed_queries(q)
    original_query = where(:messed_query => q).first.query
    select("DISTINCT(messed_query)").where(:query => original_query).map { |s| s.messed_query }
  end
  
  def self.hot_searches_on
    select("count(*) as cnt, messed_query").
    group(:query).
    order('cnt DESC').
    limit(10)
  end
  
  def self.hot_languages_on
    select("count(*) as cnt, lang").
    group(:lang).
    where("lang IS NOT NULL").
    order('cnt DESC').
    limit(10)
  end
  
  def self.find_hot_searches_on(date=Date.today)
    hot_searches_on.
    created_at_this_date(date).map { |s| [s.cnt, s.messed_query] }
  end
  
  def self.find_hot_languages_on(date=Date.today)
    hot_languages_on.
    created_at_this_date(date).map { |s| [s.cnt, s.lang, LANGUAGE_MAPPING[s.lang]] }
  end
  
  def self.find_overall_hot_searches
    hot_searches_on.map { |s| [s.cnt, s.messed_query] }
  end
  
  def self.find_overall_hot_languages
    hot_languages_on.map { |s| [s.cnt, s.lang, LANGUAGE_MAPPING[s.lang]] }
  end
  
  def self.overall_hot_languages_cache
    Rails.cache.fetch("SearchLog.find_overall_hot_languages", :expires_in => 5.days) { find_overall_hot_languages }
  end
  
  def self.overall_hot_searches_cache
    Rails.cache.fetch("SearchLog.find_overall_hot_searches", :expires_in => 5.days) { find_overall_hot_searches }
  end
  
  def self.related_searches(q)
    searches = find_messed_queries(q)
    searches.delete(q)
    return searches
  end
  
  def self.related_searches_on_lang(lang, date=Date.today)
    hot_searches_on.
    where(:lang => lang, :created_at => (date - 6.days)..(date + 2.days)).map { |s| s.messed_query }
  end
  
  ["messed_query", "query", "lang"].each do |attr|
    instance_eval <<-EOS
      def #{attr}_count(query)
        where(:#{attr} => query).count
      end
    EOS
  end
  
  def self.total_searches(q)
    log = where(:messed_query => q).first
    num = where(:query => log.query).count
    
    #num = messed_query_count(q) + query_count(q)
    den = self.count
    "#{num} / #{den} (#{(num/den.to_f*100).round(2)}%)"
  end
  
  def self.total_searches_on_lang(lang)
    num = lang_count(lang)
    den = self.count
    "#{num} / #{den} (#{(num/den.to_f*100).round(2)}%)"
  end
  
  def self.weekly_query_data(q, date=Date.today)
    select("count(*) as cnt, messed_query, created_at").
    group("date(created_at)").order('created_at').
    where(:messed_query => q, :created_at => (date-6.days)..(date+2.days)).map { |s| s.cnt }
  end
  
  def self.query_data_cache(query)
    Rails.cache.fetch("SearchLog.query_data(#{query})", :expires_in => 1.day) { query_data(query) }
  end
  
  def self.query_data(q, start_date=APP_LAUNCH_DATE, end_date=Date.today)
    select("count(*) as cnt, messed_query, created_at").
    group("date(created_at)").order('created_at').
    where(:messed_query => q, :created_at => (start_date)..(end_date)).map { |s| s.cnt }
  end
  
  def self.weekly_lang_data(lang, date=Date.today)
    select("count(*) as cnt, lang, created_at").
    group("date(created_at)").order('created_at').
    where(:lang => lang, :created_at => (date-6.days)..(date+2.days)).map { |s| s.cnt }
  end
  
  def self.lang_data_cache(query)
    Rails.cache.fetch("SearchLog.lang_data(#{query})", :expires_in => 1.day) { lang_data(query) }
  end
  
  def self.lang_data(lang, start_date=APP_LAUNCH_DATE, end_date=Date.today)
    select("count(*) as cnt, lang, created_at").
    group("date(created_at)").order('created_at').
    where(:lang => lang, :created_at => (start_date)..(end_date)).map { |s| s.cnt }
  end
  
  def self.trends_cache
    Rails.cache.fetch("SearchLog.trends", :expires_in => 1.day) { trends }
  end
  
  def self.trends
    hot_searches  = SearchLog.overall_hot_searches_cache
    hot_languages = SearchLog.overall_hot_languages_cache
    @result = { :hot_searches => hot_searches,
                :hot_languages => hot_languages,
                :total_count => SearchLog.count }
  end
  
  def self.trend_query_cache(query, date)
    Rails.cache.fetch("SearchLog.trend_query(#{query})", :expires_in => 1.day) { trend_query(query, date) }
  end
  
  def self.trend_lang_cache(query, date)
    Rails.cache.fetch("SearchLog.trend_lang(#{query})", :expires_in => 1.day) { trend_lang(query, date) }
  end
  
  def self.trend_query(query, date)
    date = date || Date.today
    date = date.to_date
    
    hot_searches  = SearchLog.overall_hot_searches_cache
    hot_languages = SearchLog.overall_hot_languages_cache
    @result = { :query_details => { :related_searches => SearchLog.related_searches(query), 
                                    :total_searches => SearchLog.total_searches(query),
                                    :weekly_query_data => SearchLog.query_data(query) }, 
                :hot_searches => hot_searches,
                :hot_languages => hot_languages }
  end
  
  def self.trend_lang(query, date)
    date = date || Date.today
    date = date.to_date
    
    hot_searches  = SearchLog.overall_hot_searches_cache
    hot_languages = SearchLog.overall_hot_languages_cache
    @result = { :query_details => { :related_searches => SearchLog.related_searches_on_lang(query), 
                                    :total_searches => SearchLog.total_searches_on_lang(query),
                                    :weekly_query_data => SearchLog.lang_data(query) }, 
                :hot_searches => hot_searches,
                :hot_languages => hot_languages }
  end
  
  private
  
    def set_lang
      self.lang = GLanguageDetector.detect(self.query)
    end
end
