# encoding: utf-8
module Trds
  class Cache < Trst::Cache

    field :name,        type: String,     default: -> {"DP_NR-#{Date.today.to_s}"}
    field :expl,        type: String,     default: 'Nume Prenume'
    field :id_intern,   type: Boolean,    default: false

    belongs_to  :unit,     class_name: 'Trds::PartnerFirmUnit', inverse_of: :dps

    index({ unit_id: 1, id_date: 1 })
    scope :by_unit_id, ->(unit_id) {where(unit_id: unit_id)}

    class << self
      # @todo
      def pos(s)
        s = s.upcase
        where(unit_id: Trds::PartnerFirm.pos(s).id)
      end
      # @todo
      def nonin(nin = true)
        where(id_intern: !nin)
      end
    end # Class methods

    #todo
    def unit
      Trds::PartnerFirm.unit_by_unit_id(unit_id) rescue nil
    end
  end # Cache
end # Trds
