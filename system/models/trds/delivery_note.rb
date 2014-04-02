# encoding: utf-8
module Trds
  class DeliveryNote
    include Mongoid::Document
    include Mongoid::Timestamps
    include Trst::ViewHelpers
    include Trst::DateHelpers

    field :name,        type: String
    field :id_date,     type: Date,     default: -> {Date.today}
    field :id_intern,   type: Boolean,  default: false
    field :doc_name,    type: String
    field :doc_plat,    type: String
    field :charged,     type: Boolean,  default: false

    alias :file_name :name

    has_many   :freights,     class_name: "Trds::FreightOut",       inverse_of: :doc_dln, dependent: :destroy
    belongs_to :doc_grn,      class_name: "Trds::Grn",              inverse_of: :dlns
    belongs_to :doc_inv,      class_name: "Trds::Invoice",          inverse_of: :dlns
    belongs_to :client,       class_name: "Trds::PartnerFirm",      inverse_of: :dlns_client
    belongs_to :client_d,     class_name: "Trds::PartnerFirmPerson",inverse_of: :dlns_client
    belongs_to :unit,         class_name: "Trds::PartnerFirmUnit",  inverse_of: :dlns
    belongs_to :signed_by,    class_name: "Trds::User",             inverse_of: :dlns

    index({ unit_id: 1, id_date: 1 })
    scope :by_unit_id, ->(unit_id) {where(unit_id: unit_id)}

    accepts_nested_attributes_for :freights,
      reject_if: ->(attrs){ attrs[:qu].to_f == 0 }

    class << self
      # @todo
      def pos(s)
        where(unit_id: Trds::PartnerFirm.pos(s).id)
      end
      # @todo
      def nonin(nin = true)
        where(id_intern: !nin)
      end
      # @todo
      def charged(b = true)
        where(charged: b)
      end
      # @todo
      def sum_freights_grn
        all.each_with_object({}) do |dn,s|
          dn.freights.asc(:id_stats).each_with_object(s) do |f,s|
            if s[f.key].nil?
              s[f.key] = [f.freight.name,f.freight.id_stats,f.um,f.pu,f.qu,f.val,f.tva]
            else
              s[f.key][4] += f.qu
              s[f.key][5] += f.val
            end
          end
        end
      end
      # @todo
      def sum_freights_inv
        all.each_with_object({}) do |dn,s|
          dn.freights.asc(:id_stats).each_with_object(s) do |f,s|
            key = "#{f.id_stats}_#{"%07.4f" % f.pu_invoice}"
            if s[key].nil?
              s[key] = [f.freight.name,f.freight.id_stats,f.um,f.pu,f.qu,f.val,f.pu_invoice,f.val_invoice,f.tva_invoice,f.out_invoice,f.freight.tva]
            else
              s[key][4] += f.qu
              s[key][5] += f.val
              s[key][7] += f.val_invoice
              s[key][8] += f.tva_invoice
              s[key][9] += f.out_invoice
            end
          end
        end
      end
      # @todo
      def auto_search(params)
        unit_id = params[:uid]
        day     = params[:day].split('-').map(&:to_i)
        where(unit_id: unit_id,id_date: Date.new(*day))
        .or(doc_name: /#{params[:q]}/i)
        .or(:client_id.in => Trds::PartnerFirm.only(:id).where(name: /#{params[:q]}/i).map(&:id))
        .each_with_object([]) do |d,a|
          a << {id: d.id,
                text: {
                        name:  d.name,
                        title: d.freights_list.join("\n"),
                        doc_name: d.doc_name,
                        client:   d.client.name[1]}}
        end
      end
    end # Class methods

    # @todo
    def unit
      Trds::PartnerFirm.unit_by_unit_id(unit_id) rescue nil
    end
    # @todo
    def client_d
      Trds::PartnerFirm.person_by_person_id(client_d_id) rescue nil
    end
    # @todo
    def increment_name(unit_id)
      dlns = Trds::DeliveryNote.by_unit_id(unit_id).yearly(Date.today.year)
      if dlns.count > 0
        name = dlns.asc(:name).last.name.next
      else
        unit = Trds::PartnerFirm.unit_by_unit_id(unit_id)
        prfx = Date.today.year.to_s[-2..-1]
        name = "#{unit.firm.name[0][0..2].upcase}_#{unit.slug}_AEAA-#{prfx}00001"
      end
      name
    end
    # @todo
    def freights_list
      freights.asc(:id_stats).each_with_object([]) do |f,r|
        r << "#{f.freight.name}: #{"%.2f" % f.qu} #{f.um} ( #{"%.4f" % f.pu} )"
      end
    end
  end # DeliveryNote
end # Trds