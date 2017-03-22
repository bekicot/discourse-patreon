require 'openssl'

class ::Patreon::PatreonWebhookController < ActionController::Base

  TRIGGERS = ['pledges:create', 'pledges:update', 'pledges:delete']

  def index

    raise Discourse::InvalidAccess.new unless TRIGGERS.include?(request.headers['X-Patreon-Event'])

    raise Discourse::InvalidAccess.new unless valid_signature?(request.headers['X-Patreon-Signature'], request.raw_post)

    opts = {}
    opts[:current_site_id] = RailsMultisite::ConnectionManagement.current_db
    klass = 'Patreon::SyncPatronsToGroups'.constantize
    Sidekiq::Client.enqueue(klass, opts)

    render nothing: true, status: 200
  end

  private

  def valid_signature?(signature, data)
    digest = OpenSSL::Digest::MD5.new
    signature == OpenSSL::HMAC.hexdigest(digest, SiteSetting.patreon_client_secret, data)
  end
end