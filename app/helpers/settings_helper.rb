module SettingsHelper

  def feature?(name)
    setting["feature.#{name}"].presence
  end

  def any_feature?(feature_list)
    feature_list.inject(false){|acc,name| feature?(name) || acc }
  end
  
  def setting
    @all_settings ||= Hash[ Setting.all.map{|s| [s.key, s.value.presence]} ]
  end

end
