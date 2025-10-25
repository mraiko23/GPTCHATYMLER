class Administrator < ApplicationRecord
  attribute :name, :string
  attribute :password_digest, :string
  attribute :role, :string
  attribute :first_login, :boolean, default: true
  
  attr_accessor :password, :password_confirmation
  
  validates :name, presence: true
  validate :name_uniqueness
  validates :role, presence: true, inclusion: { in: %w[admin super_admin] }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  has_many :admin_oplogs, dependent: :destroy
  
  before_save :encrypt_password, if: -> { password.present? }

  # Role constants
  ROLES = %w[admin super_admin].freeze

  # Role check methods
  def super_admin?
    role == 'super_admin'
  end

  def admin?
    role == 'admin'
  end

  # Permission check methods
  def can_manage_administrators?
    super_admin?
  end

  def can_delete_administrators?
    super_admin?
  end

  def can_be_deleted_by?(current_admin)
    return false unless current_admin.can_delete_administrators?
    # Super admin cannot delete themselves
    return false if self == current_admin
    true
  end

  # Display role name
  def role_name
    case role
    when 'super_admin'
      'Super Admin'
    when 'admin'
      'Admin'
    else
      role.humanize
    end
  end

  # Role options for form select
  def self.role_options
    [
      ['Admin', 'admin'],
      ['Super Admin', 'super_admin']
    ]
  end
  
  # Password authentication
  def authenticate(password)
    return false unless password_digest.present?
    BCrypt::Password.new(password_digest).is_password?(password) ? self : false
  end
  
  private
  
  def name_uniqueness
    existing = Administrator.find_by(name: name)
    if existing && existing.id != id
      errors.add(:name, 'has already been taken')
    end
  end
  
  def password_required?
    password_digest.blank? || password.present?
  end
  
  def encrypt_password
    require 'bcrypt'
    self.password_digest = BCrypt::Password.create(password)
  end
end
