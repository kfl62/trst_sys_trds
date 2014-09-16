# encoding: utf-8
module Trds
  class Payment < Trst::Payment

    belongs_to :doc_inv,      class_name: "Trds::Invoice",              inverse_of: :pyms

    class << self
    end # Class methods

  end # Payment
end # Trds
