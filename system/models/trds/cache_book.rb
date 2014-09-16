# encoding: utf-8
module Trds
  class CacheBook < Trst::CacheBook

    embeds_many :lines,       class_name: 'Trds::CacheBook::Line',      cascade_callbacks: true

  end # CacheBook

  class CacheBook::Line < Trst::CacheBookLine

    embedded_in :cb,          class_name: 'Trds::CacheBook',            inverse_of: :lines

  end # CacheBookIn
end #Trds
