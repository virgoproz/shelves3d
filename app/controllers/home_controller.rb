
require 'oauth'

class HomeController < ApplicationController
  KEY = 'L1biaqDh5wN8USqxqqyrA'
  SECRET = 'R6KXCYMIAaeZP6oacuKOESAks0fWzSvgK2qF6CQq4o'
  WEBSITE = 'http://www.goodreads.com'

  OAUTH_CALLBACK = Rails.env.production? ? "http://shelves3d.herokuapp.com/home/authorized" :
                                           "http://localhost:3000/home/authorized"

  def index

  end

  def auth_request
    consumer = OAuth::Consumer.new(KEY, SECRET, :site=>WEBSITE)
    session[:request_token] = consumer.get_request_token
    redirect_url = "#{session[:request_token].authorize_url}&oauth_callback=#{OAUTH_CALLBACK}"
    redirect_to redirect_url
  end

  def authorized

    access_token = session[:request_token].get_access_token
    session.delete(:request_token)

    session[:access_token] = access_token.token
    session[:access_token_secret] = access_token.secret

    response = access_token.get('/api/auth_user')
    xml_response = Nokogiri.XML(response.body)
    session[:user_id] = xml_response.xpath("//@id").to_s

    #consumer = OAuth::Consumer.new(KEY, SECRET, :site => WEBSITE)
    #access_token = OAuth::AccessToken.new(consumer, session[:access_token], session[:access_token_secret])

    response = access_token.get("/owned_books/user?format=xml&id=#{session[:user_id]}")
    xml_response = Nokogiri.XML(response.body)
    books_nodes = xml_response.xpath("//book")

    owned_books = []

    (1..20).each do
      books_nodes.each do |book_node|
        book_entry = OwnedBook.new(book_node)
        owned_books.push(book_entry)
      end
    end

    session[:owned_books] = owned_books
    redirect_to "/home/index"
  end

  def proxy
    #@request.env["REQUEST_URI"]
    #url = "http://www.photographers.it/free/images/projects/800_1349864926_12823.jpg"
    url = URI.parse(params["url"])

    result = Net::HTTP.get_response(url)
    send_data result.body, :type => 'image/jpeg', :disposition => 'inline'

  end


end
