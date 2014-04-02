# encoding: utf-8
module Trds
  class Freight < Trst::Freight

    field       :tva,      type: Float,     default: 0.24

    has_many    :ins,      class_name: "Trds::FreightIn",       inverse_of: :freight
    has_many    :outs,     class_name: "Trds::FreightOut",      inverse_of: :freight
    has_many    :stks,     class_name: "Trds::FreightStock",    inverse_of: :freight

    after_update :handle_id_stats

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
      def stks
        ids = all.pluck(:id)
        Trds::FreightStock.where(:freight_id.in => ids)
      end
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
    end # Class methods

    def key(p)
      "#{id_stats}_#{"%.4f" % p}"
    end
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
    def handle_id_stats
      if id_stats_changed?
        [ins,outs,stks].each do |m|
          m.where(id_stats: id_stats_was).update_all(id_stats: id_stats)
        end
      end
    end
  end # Freight
end # Trds
