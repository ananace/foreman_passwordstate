# frozen_string_literal: true

module ForemanPasswordstate
  module OperatingsystemExtensions
    def root_user
      if family == 'Windows'
        'Administrator'
      else
        'root'
      end
    end
  end
end
