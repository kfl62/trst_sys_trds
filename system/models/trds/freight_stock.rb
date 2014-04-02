# encoding: utf-8
module Trds
  class FreightStock
    include Mongoid::Document
    include Mongoid::Timestamps
    include Trst::ViewHelpers
    include Trst::DateHelpers

    field :id_date,     type: Date
    field :id_stats,    type: String
    field :id_intern,   type: Boolean,   default: false
    field :um,          type: String,    default: "kg"
    field :pu,          type: Float,     default: 0.00
    field :qu,          type: Float,     default: 0.00
    field :val,         type: Float,     default: 0.00

    belongs_to  :freight,  class_name: 'Trds::Freight',     inverse_of: :stks
    belongs_to  :doc_stk,  class_name: 'Trds::Stock',       inverse_of: :freights

    index({ id_stats: 1, freight_id: 1, id_date: 1 })
    index({ freight_id: 1, id_stats: 1, pu: 1, id_date: 1 })
    index({ id_stats: 1, pu: 1, id_date: 1 })
    index({ freight_id: 1, doc_stk_id: 1, qu: 1})
    scope :stock_now, where(id_date: Date.new(2000,1,31))

    after_update :handle_value

    class << self
      # @todo
      def by_id_stats(ids,lst = false)
        c = ids.scan(/\d{2}/).each{|g| g.gsub!("00","\\d{2}")}.join
        result = where(id_stats: /#{c}/).asc(:name)
        if lst
          c = ids.gsub(/\d{2}$/,"\\d{2}")
          result = where(id_stats: /#{c}/).asc(:id_stats)
          result = ids == "00000000" ? ids : result.last.nil? ? ids.next : result.last.id_stats.next
        end
        result
      end
      # @todo
      def keys(p = 2)
        p  = 0 unless p # keys(false) compatibility
        ks = all.each_with_object([]){|f,k| k << "#{f.id_stats}_#{"%.#{p}f" % f.pu}"}.uniq.sort!
        ks = all.each_with_object([]){|f,k| k << "#{f.id_stats}"}.uniq.sort! if p.zero?
        ks
      end
      # @todo
      def by_key(key)
        id_stats, pu = key.split('_')
        pu.nil? ? where(id_stats: id_stats) : where(id_stats: id_stats, pu: pu.to_f)
      end
      # @todo
      def nonin(nin = true)
        where(id_intern: !nin)
      end
      # @todo
      def pos(s)
        where(:doc_stk_id.in => Trds::Stock.where(unit_id: PartnerFirm.pos(s).id).pluck(:id))
      end
    end # Class methods

    # @todo
    def view_filter
      [id, freight.name]
    end
    # @todo
    def unit
      Trds::PartnerFirm.unit_by_unit_id(doc_stk.unit_id)
    end
    # @todo
    def name
      freight.name
    end
    # @todo
    def tva
      freight.tva
    end
    # @todo
    def doc
      doc_stk
    end
    # @todo
    def key
      "#{id_stats}_#{"%.4f" % pu}"
    end

    protected
    # @todo
    def handle_value
      set :val, (pu * qu).round(2)
    end
  end # FreightStock
end # Trds