module ApplicationHelper

  def home_page?
    return false if user_signed_in?
    # Using path because fullpath yields false negatives since it contains
    # parameters too
    ['/', '/participa'].include? request.path
  end

  def header_css
    home_page? ? '' : 'results'
  end

  # if current path is /debates current_path_with_query_params(foo: 'bar') returns /debates?foo=bar
  # notice: if query_params have a param which also exist in current path, it "overrides" (query_params is merged last)
  def current_path_with_query_params(query_parameters)
    url_for(request.query_parameters.merge(query_parameters))
  end

end
