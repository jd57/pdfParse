#!/usr/bin/env ruby
require 'pp'
require 'zlib'
class File
  def to int
    self.sysseek(int,IO::SEEK_SET)
  end
end
class String
  def i16
    self.to_i(16)
  end
  def i10
    self.to_i(10)
  end
  def i2
    self.to_i(2)
  end
  def bin
    self.unpack("B*")[0]
  end
  def hex
    self.unpack("H*")[0]
  end
  def raw
    [self].pack("H*")
  end
  def praw
    self.hex.p16
  end
  def p16
    self.chars.each_slice(32).each_with_index do |e,n|
      a=e.join.scan(/../)[0,8].join(" ")
      b=e.join.scan(/../)[8,8].join(" ")
      puts "%0.7d0 %s  %s" % [n, a,b]
    end
  end
end
class PDF
  class << self
    def init str
      @@name=str
      @@content=File.read(str)
      @@hex = @@content.hex
      @@idf=Hash[
	      :com=>       "(0a|0d)",
	      :trailer=>   "trailer".hex ,
	      :xref=>      "xref".hex     ,
	      :startxref=> "startxref".hex,
	      :EOf=>       "%%EOF".hex    
      ]
      get_sidx
      get_trailer
      get_xref
      get_obj
      txt= @@obj[121]
      test txt

      self.make "test.pdf"
    end
    def make name
      @@newXref=[]
      @@newFile=File.new(name,"w")
      makeHeader
      makeObj
      makeXref
      makeTrailer
      makeStartXref
      @@newFile.close
    end
    def makeStartXref
      @@newFile.puts "startxref"
      @@newFile.puts @@newStartXref
      @@newFile.puts "%%EOF"
    end
    def makeTrailer
      @@newFile.puts "trailer"+@@trailer
    end
    def makeXref
      @@newStartXref=@@newFile.size
      @@newFile.puts "xref"
      @@newFile.puts "0 #{@@newXref.size}"
      @@newXref.each do |id,s,t|
        @@newFile.puts "%-0.10d %-0.5d %s" % [id,s,t]
      end
    end
      
    def makeObj
      idx=0
      @@xref.each_with_index do |e,n|
        if n==0
	  @@newXref.push [0,65535,"f"]
	else
	  @@newXref.push [idx,@@xref[n][1],@@xref[n][2]]
          @@newFile.puts "#{n} #{@@xref[n][1]} obj"+@@obj[n]+"endobj"
	end
	idx=@@newFile.size
      end
    end
    def makeHeader
      @@newFile.puts "%PDF-1.2\n"
    end
    def test str
      hex=match_stream(str)
      txt= Zlib::Inflate.inflate(hex)
      puts txt
#      puts txt.scan(/\((.*?)\)/).join(" ")
    end
    def get_sidx
      @@sidx=@@hex.match(/#{@@idf[:startxref]}#{@@idf[:com]}(?<sxref>.*?)#{@@idf[:com]}#{@@idf[:EOF]}/)[:sxref].raw.i10
    end
    def match_stream str
      str.hex.match(/#{("stream"+"\n").hex}(.*)#{"endstream".hex}/)[1].raw
    end
    def get_trailer
      @@trailer=@@hex.match(/#{@@idf[:trailer]}(?<trailer>.*)#{@@idf[:startxref]}/)[:trailer].raw
    end
    def get_obj
      f=File.open(@@name)
      @@obj=[]
      @@xref.each_with_index do |e,n|
        if n > 0
          idx,vers,use=e
	  f.pos
          f.sysseek(idx.to_i,IO::SEEK_SET)
	  f.gets(sep='obj')
	  txt=f.gets(sep='endobj').gsub('endobj','')
	  @@obj[n]=txt
	end
      end
    end
    def get_xref
      f=File.open(@@name)
      f.sysseek(@@sidx,IO::SEEK_SET)
      f.gets
      []
      start,num= f.gets.split
      if start=="0"
        @@xref=(0...num.to_i).map do |n|
        f.gets.split
        end
      else 
        pp "Error, xref start not 0"
      end
      f.close

    end
  end
end 

#f=File.open("sample.pdf")
#f.sysseek(sidx,IO::SEEK_SET)
#pp f.gets
#pp f.gets

PDF.init("sample.pdf")

