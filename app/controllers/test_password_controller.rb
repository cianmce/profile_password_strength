class TestPasswordController < ApplicationController
  SUPPORTED_GEMS = ["fnando/password_strength", "bdmac/strong_password"]
  PASSWORD_LENGTH_LIMITS = {
    "fnando/password_strength" => 50_000,
    "bdmac/strong_password" => 2_000_000
  }

  def index
  end

  def test_password
    password = user_params[:password] || ""
    username = user_params[:name] || ""
    @gem_name = user_params[:gem]
    if user_params[:password_length].to_i > 0
      length = [user_params[:password_length].to_i, 10_000_000].min
      password = SecureRandom.hex(length/2)
    end

    @password_truncated = password.truncate(30)
    @username_truncated = username.truncate(30)
    @password_length = password.length
    Rails.logger.info "password_length: #{@password_length}"
    Rails.logger.info "gem_name: #{@gem_name}"

    flash[:error] = "Gem not supported" unless SUPPORTED_GEMS.include? @gem_name    
    flash[:error] = "Password is too long for '#{@gem_name}'. Limit is '#{PASSWORD_LENGTH_LIMITS[@gem_name]}'" if @password_length > PASSWORD_LENGTH_LIMITS[@gem_name]
    flash[:error] = "Username is too long for '#{@gem_name}'. Limit is '#{PASSWORD_LENGTH_LIMITS[@gem_name]}'" if username.length > PASSWORD_LENGTH_LIMITS[@gem_name]
    if flash[:error].blank?
      @timer = Benchmark.measure { @strength = test_password_gem(username, password) }
      Rails.logger.info "Timer: #{@timer}"
      @password = password
      @username = username
    end

    render :index
  end

  private

  def test_password_gem(username, password)
    if @gem_name == "fnando/password_strength"
      PasswordStrength.test(username, password).score
    else
      StrongPassword::StrengthChecker.new(password).calculate_entropy(use_dictionary: true, extra_dictionary_words: [username])
    end
  end

  def user_params
    params.require(:user).permit(:name, :password, :gem, :password_length)
  end
end
