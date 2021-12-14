class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token

  before_save :downcase_email
  before_create :create_activate_digest
  validates(:name, presence: true, length: { maximum: 50 })
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # set random string as a token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # set new token as remember_token and set remember_digest with User.digest(token)
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    # digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
    # update_columns enable to call database 1 time to change things.
    # but callback and validation don't run
    # update_attribute(:activated, true)
    # update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

  def downcase_email
    self.email = email.downcase
    # self.email = self.email.downcase
    # self.email.downcase!
  end

  # set activation_token and activation_digest
  def create_activate_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
