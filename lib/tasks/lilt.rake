namespace :lilt do
  desc 'Checks for project completion and imports completed documents'
  task import: :environment do
    puts '[lilt:import] Checking for project'

    project_id = ENV['LILT_PROJECT']
    api_key = ENV['LILT_API_KEY']

    result = HTTParty.get("https://lilt.com/2/projects/?id=#{project_id}&key=#{api_key}", headers: { 'Accept': 'application/json'})

    project = JSON.parse(result.response.body)[0]

    if project['state'] == 'done'
      puts '[lilt:import] Project is completed, importing.'

      # download file
      doc_id = project['document'][0]['id']
      result = HTTParty.get("https://lilt.com/2/documents/files?id=#{doc_id}&is_xliff=false&key=#{api_key}", headers: { 'Accept': 'application/json'})
      results = JSON.parse(result.response.body)

      commit = Commit.includes(:keys).last
      user = User.first

      results.each do |obj|
        obj.each_pair do |k,v|
          v.gsub!("'", "\u2018")
          Chewy.strategy(:atomic) do
            key = commit.keys.where(key: k).first
            translation = key.translations.where(rfc5646_locale: 'fr').first
            translation.copy = v
            translation.translated = true
            translation.translation_date = Time.now
            translation.translator_id = user.id
            puts "[lilt:import] Importing #{k}: '#{v}'"
            save_result = translation.save
            if save_result
              puts "[lilt:import] #{k} imported successfully."
            else
              puts "[lilt:import] ERROR #{k} not imported."
            end
          end
        end
      end
    end

    puts '[lilt:import] Import finished.'
  end
end
