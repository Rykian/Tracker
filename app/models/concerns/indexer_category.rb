# frozen_string_literal: true

# Torznab standard categories
# Based on: https://torznab.github.io/spec-1.3-draft/torznab/Specification-v1.3.html
module IndexerCategory
  CATEGORIES = {
    1000 => "Console",
    1010 => "Console/NDS",
    1020 => "Console/PSP",
    1030 => "Console/Wii",
    1040 => "Console/Xbox",
    1050 => "Console/Xbox 360",
    1060 => "Console/Wiiware",
    1070 => "Console/Xbox 360 DLC",
    1080 => "Console/PS3",

    2000 => "Movies",
    2010 => "Movies/Foreign",
    2020 => "Movies/Other",
    2030 => "Movies/SD",
    2040 => "Movies/HD",
    2045 => "Movies/UHD",
    2050 => "Movies/BluRay",
    2060 => "Movies/3D",
    2070 => "Movies/DVD",
    2080 => "Movies/WEB-DL",

    3000 => "Audio",
    3010 => "Audio/MP3",
    3020 => "Audio/Video",
    3030 => "Audio/Audiobook",
    3040 => "Audio/Lossless",
    3050 => "Audio/Other",
    3060 => "Audio/Foreign",
    3070 => "Audio/Podcast",
    3080 => "Audio/Karaoke",

    4000 => "PC",
    4010 => "PC/0day",
    4020 => "PC/ISO",
    4030 => "PC/Mac",
    4040 => "PC/Phone-Other",
    4050 => "PC/Games",
    4060 => "PC/Phone-iOS",
    4070 => "PC/Phone-Android",
    4080 => "PC/Phone-Windows",

    5000 => "TV",
    5010 => "TV/WEB-DL",
    5020 => "TV/Foreign",
    5030 => "TV/SD",
    5040 => "TV/HD",
    5045 => "TV/UHD",
    5050 => "TV/Other",
    5060 => "TV/Sport",
    5070 => "TV/Anime",
    5080 => "TV/Documentary",
    5090 => "TV/x265",

    6000 => "XXX",
    6010 => "XXX/DVD",
    6020 => "XXX/WMV",
    6030 => "XXX/XviD",
    6040 => "XXX/x264",
    6050 => "XXX/Pack",
    6060 => "XXX/ImageSet",
    6070 => "XXX/Other",
    6080 => "XXX/SD",

    7000 => "Books",
    7010 => "Books/Mags",
    7020 => "Books/EBook",
    7030 => "Books/Comics",
    7040 => "Books/Technical",
    7050 => "Books/Other",
    7060 => "Books/Foreign",

    8000 => "Other",
    8010 => "Other/Misc",
    8020 => "Other/Hashed"
  }.freeze

  def self.all
    CATEGORIES
  end

  def self.ids
    CATEGORIES.keys
  end

  def self.names
    CATEGORIES.values
  end

  def self.name_for(id)
    CATEGORIES[id]
  end

  def self.valid_id?(id)
    CATEGORIES.key?(id)
  end
end
