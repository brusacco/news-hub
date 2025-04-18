# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # or specify your frontend domain like 'https://example.com'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: ['Cross-Origin-Resource-Policy'] # expose custom headers if needed
  end
end
