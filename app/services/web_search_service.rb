require 'net/http'
require 'json'
require 'uri'
require 'nokogiri'

class WebSearchService < ApplicationService
  def initialize(query:, max_results: 5)
    @query = query
    @max_results = max_results
  end

  def call
    return { error: 'Пустой запрос' } if @query.blank?
    
    begin
      # Try multiple search approaches
      results = []
      
      # 1. Try DuckDuckGo Instant Answer API
      ddg_results = search_duckduckgo(@query)
      results.concat(ddg_results[:results]) if ddg_results[:results].present?
      
      # 2. Try HTML scraping from DuckDuckGo (more reliable)
      if results.length < @max_results
        html_results = scrape_duckduckgo_html(@query)
        results.concat(html_results.first(@max_results - results.length))
      end
      
      # 3. Try Wikipedia API for encyclopedic queries
      if results.empty? && looks_like_encyclopedic_query?(@query)
        wiki_results = search_wikipedia(@query)
        results.concat(wiki_results) if wiki_results.present?
      end
      
      # If still no results, provide fallback
      if results.empty?
        results = simple_web_search(@query)
      end
      
      {
        success: true,
        query: @query,
        results: results.first(@max_results),
        summary: generate_summary(results.first(@max_results))
      }
    rescue => e
      Rails.logger.error "WebSearchService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        error: 'Ошибка поиска в интернете. Попробуйте позже.',
        details: Rails.env.development? ? e.message : nil
      }
    end
  end

  private

  def search_duckduckgo(query)
    encoded_query = URI.encode_www_form_component(query)
    url = "https://api.duckduckgo.com/?q=#{encoded_query}&format=json&no_html=1&skip_disambig=1"
    
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    unless response.code == '200'
      return { results: [] }
    end
    
    data = JSON.parse(response.body)
    results = []
    
    # Extract instant answer
    if data['AbstractText'].present?
      results << {
        title: data['AbstractSource'] || 'DuckDuckGo',
        snippet: data['AbstractText'],
        url: data['AbstractURL'],
        source: 'instant_answer'
      }
    end
    
    # Extract related topics
    if data['RelatedTopics'].present?
      data['RelatedTopics'].first(@max_results - results.length).each do |topic|
        next unless topic['Text'].present?
        
        results << {
          title: topic['FirstURL']&.split('/')&.last&.humanize || 'Related Topic',
          snippet: topic['Text'],
          url: topic['FirstURL'],
          source: 'related_topic'
        }
      end
    end
    
    { results: results }
  end
  
  def scrape_duckduckgo_html(query)
    encoded_query = URI.encode_www_form_component(query)
    url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5
    
    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    
    response = http.request(request)
    
    return [] unless response.code == '200'
    
    doc = Nokogiri::HTML(response.body)
    results = []
    
    # Extract search results from HTML
    doc.css('.result').first(@max_results).each do |result|
      title_elem = result.at_css('.result__title')
      snippet_elem = result.at_css('.result__snippet')
      url_elem = result.at_css('.result__url')
      
      next unless title_elem && snippet_elem
      
      # Extract URL
      result_url = url_elem&.text&.strip || ''
      result_url = "https://#{result_url}" unless result_url.start_with?('http')
      
      results << {
        title: title_elem.text.strip,
        snippet: snippet_elem.text.strip,
        url: result_url,
        source: 'duckduckgo_html'
      }
    end
    
    results
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "DuckDuckGo HTML scraping timeout: #{e.message}"
    []
  rescue => e
    Rails.logger.warn "DuckDuckGo HTML scraping failed: #{e.message}"
    []
  end
  
  def search_wikipedia(query)
    encoded_query = URI.encode_www_form_component(query)
    url = "https://ru.wikipedia.org/w/api.php?action=query&list=search&srsearch=#{encoded_query}&format=json&utf8=1&srlimit=3"
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5
    
    response = http.get(uri.request_uri)
    
    return [] unless response.code == '200'
    
    data = JSON.parse(response.body)
    results = []
    
    if data['query'] && data['query']['search']
      data['query']['search'].each do |item|
        next unless item['title'].present?
        
        # Clean HTML from snippet
        snippet = item['snippet'].gsub(/<[^>]+>/, '')
        
        results << {
          title: item['title'],
          snippet: snippet,
          url: "https://ru.wikipedia.org/wiki/#{URI.encode_www_form_component(item['title'])}",
          source: 'wikipedia'
        }
      end
    end
    
    results
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "Wikipedia search timeout: #{e.message}"
    []
  rescue => e
    Rails.logger.warn "Wikipedia search failed: #{e.message}"
    []
  end
  
  def looks_like_encyclopedic_query?(query)
    # Check if query looks like it's asking for factual/encyclopedic information
    query_lower = query.downcase
    encyclopedic_patterns = [
      /что такое/,
      /кто такой|кто такая/,
      /когда появился|когда создан/,
      /где находится/,
      /история/,
      /определение/,
      /значение/
    ]
    
    encyclopedic_patterns.any? { |pattern| query_lower.match?(pattern) }
  end
  
  def simple_web_search(query)
    # Fallback: Return some basic search suggestions
    [
      {
        title: "Поиск: #{query}",
        snippet: "К сожалению, не удалось найти актуальную информацию в интернете по запросу '#{query}'. Попробуйте переформулировать вопрос или задать более конкретный запрос.",
        url: "https://duckduckgo.com/?q=#{URI.encode_www_form_component(query)}",
        source: 'fallback'
      }
    ]
  end
  
  def generate_summary(results)
    return 'Нет результатов поиска' if results.empty?
    
    summary_parts = []
    
    results.each_with_index do |result, index|
      source_label = case result[:source]
                     when 'instant_answer' then '[Быстрый ответ]'
                     when 'wikipedia' then '[Wikipedia]'
                     when 'duckduckgo_html' then '[Web]'
                     else '[Результат]'
                     end
      
      snippet = result[:snippet].to_s.strip
      snippet = snippet.truncate(200) if snippet.length > 200
      
      summary_parts << "#{index + 1}. #{source_label} #{result[:title]}\n   #{snippet}\n   Источник: #{result[:url]}"
    end
    
    "Результаты поиска по запросу '#{@query}':\n\n" + summary_parts.join("\n\n")
  end
end
