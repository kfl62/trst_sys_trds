# encoding: utf-8
module Trds
  class Freight < Trst::Freight

    field       :tva,         type: Float,                              default: 0.24
    field       :csn,         type: Hash
    # temproray solutioin, @todo  convert to Hash
    field       :pu,          type: Float,                              default: 0.0

    has_many    :ins,         class_name: "Trds::FreightIn",            inverse_of: :freight
    has_many    :outs,        class_name: "Trds::FreightOut",           inverse_of: :freight
    has_many    :stks,        class_name: "Trds::FreightStock",         inverse_of: :freight

    index({ id_stats: 1 })

    after_create :handle_csn
    after_update :handle_id_stats
    after_update :order_csn

    class << self
      # @todo
      def ins
        ids = all.pluck(:id)
        Trds::FreightIn.where(:freight_id.in => ids)
      end
      # @todo
      def outs
        ids = all.pluck(:id)
        Trds::FreightOut.where(:freight_id.in => ids)
      end
      # @todo
      def stks
        ids = all.pluck(:id)
        Trds::FreightStock.where(:freight_id.in => ids)
      end
    end # Class methods

    # @todo
    def criteria_name
      result = []
      c0, c1, c2 = id_stats.scan(/\d{2}/)
      I18n.t('clns.freight.c0').each_with_object(result){|a,r| r << a[1] if a[0] == c0}
      I18n.t("clns.freight.c1.#{c0}").each_with_object(result){|a,r| r << a[1] if a[0] == c1} unless c1 == '00'
      I18n.t("clns.freight.c2.#{c0}.#{c1}").each_with_object(result){|a,r| r << a[1] if a[0] == c2} unless c2 == '00'
      result.join(' - ')
    end

    protected
    # @todo
    def handle_csn
      set :csn, {dflt: name}
    end
    # @todo
    def handle_id_stats
      if id_stats_changed?
        [ins,outs,stks].each do |m|
          m.where(id_stats: id_stats_was).update_all(id_stats: id_stats)
        end
      end
    end
    # @todo
    def order_csn
      if csn.count > 1
        h_def = {dflt: csn.delete('dflt')}
        h_all = Hash[csn.map{|o| o.unshift(Trds::PartnerFirm.find(o[0]).name[0])}.sort.map{|o| o.shift;o}]
        set :csn, h_def.merge(h_all)
      end
    end
  end # Freight
end # Trds
