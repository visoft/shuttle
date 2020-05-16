class Net::HTTP::ImmutableHeaderKey
  attr_reader :key

  def initialize(key)
    @key = key
  end

  def downcase
    self
  end

  def capitalize
    self
  end

  def split(*)
    [self]
  end

  def hash
    key.hash
  end

  def eql?(other)
    key.eql? other.key.eql?
  end

  def to_s
    def self.to_s
      key
    end
    self
  end
end

class Lilt::ProjectsController < ApplicationController

  before_filter :translator_required
  before_filter :locale_access_required
  before_filter :find_locale
  before_filter :find_project, only: :show

  respond_to :html, only: :show
  # Displays a web page where a translator can view and edit the translations
  # for a project in a `locale`.
  #
  # Routes
  # ------
  #
  # * `GET /locales/:locale_id/projects/:id
  #
  # Path Parameters
  # ---------------
  #
  # |             |                                 |
  # |:------------|:--------------------------------|
  # | `locale_id` | The RFC 5646 code for a locale. |
  # | `id`        | The slug of a {Project}.        |

  def show
    lilt_project_id = ENV['LILT_PROJECT']
    lilt_memory_id = ENV['LILT_MEMORY']
    lilt_api_key = ENV['LILT_API_KEY']

    # check for document????? how?
    lilt_document = nil

    # build a file of the keys

    commit = Commit.includes(:keys, keys: :translations).where(revision: params[:commit]).where(translations: { rfc5646_locale: 'fr'}).first
    keys = []

    commit.keys.each do |key|
      keys << { "#{key.key}": key.source_copy }
    end

    json = keys.to_json

    @lilt_document = HTTParty.post "https://lilt.com/2/documents/files?key=#{lilt_api_key}",
       verify: false, # allows for localhost proxy Charles to work
       headers: {
                  'Transfer-Encoding' => 'chunked',
                  'Content-Type' => 'application/octet-stream',
                   Net::HTTP::ImmutableHeaderKey.new('LILT-API') => "{ \"name\": \"test.json\", \"project_id\": #{lilt_project_id} }"
                },
       body_stream: StringIO.new(json)
  end

  private

  def find_locale
    @locale = Locale.from_rfc5646(params[:locale_id])
    unless @locale
      respond_to do |format|
        format.any { head :not_found }
      end
    end
  end

  def find_project
    @project = Project.find_from_slug!(params[:id])
  end

  def locale_access_required
    if current_user.has_access_to_locale?(params[:locale_id])
      true
    else
      respond_to do |format|
        format.html { redirect_to root_url, alert: t('controllers.locale.projects.locale_access_required') }
        format.any { head :forbidden }
      end
      false
    end
  end
end
