class SearchLog < ActiveRecord::Base
  def self.find_messed_queries(q)
    select("DISTINCT(messed_query)").where(:query => q).map { |s| s.messed_query }
  end
  
  def self.find_hot_searches_on(date=Date.today)
    select("count(*) as cnt, messed_query").group(:query).order('cnt DESC').limit(10).where(:created_at => (date)..(date+1.day)).map { |s| [s.cnt, s.messed_query] }
  end
  
  def self.find_hot_languages_on(date=Date.today)
    select("count(*) as cnt, lang").group(:lang).order('cnt DESC').limit(10).where(:created_at => (date)..(date+1.day)).map { |s| [s.cnt, s.lang, LANGUAGE_MAPPING[s.lang]] }
  end
  
  def self.find_overall_hot_searches
    select("count(*) as cnt, messed_query").group(:query).order('cnt DESC').limit(10).map { |s| [s.cnt, s.messed_query] }
  end
  
  def self.related_searches(q)
    searches = find_messed_queries(q)
    searches.delete(q)
    return searches
  end
  
  def self.related_searches_on_lang(lang, date=Date.today)
    select("count(*) as cnt, messed_query").group(:query).order('cnt DESC').limit(10).where(:lang => lang, :created_at => (date-6.days)..(date+2.days)).map { |s| s.messed_query }
  end
  
  def self.messed_query_count(q)
    where(:messed_query => q).count
  end
  
  def self.query_count(q)
    where(:query => q).count
  end
  
  def self.lang_count(lang)
    where(:lang => lang).count
  end
  
  def self.total_searches(q)
    num = messed_query_count(q) + query_count(q)
    den = self.count
    "#{num} / #{den} (#{(num/den.to_f*100).round(2)}%)"
  end
  
  def self.total_searches_on_lang(lang)
    num = lang_count(lang)
    den = self.count
    "#{num} / #{den} (#{(num/den.to_f*100).round(2)}%)"
  end
  
  def self.weekly_query_data(q, date=Date.today)
    select("count(*) as cnt, messed_query, created_at").group("date(created_at)").order('created_at').where(:messed_query => q, :created_at => (date-6.days)..(date+2.days)).map { |s| s.cnt }
  end
  
  def self.weekly_lang_data(lang, date=Date.today)
    select("count(*) as cnt, lang, created_at").group("date(created_at)").order('created_at').where(:lang => lang, :created_at => (date-6.days)..(date+2.days)).map { |s| s.cnt }
  end
end
