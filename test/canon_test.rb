#!/usr/bin/env ruby

## canon_test.rb
##

require_relative './test_helper'

require_relative '../lib/wad'

require 'data-utils/canonical'

class Canon_Tests < Minitest::Test

  def test_to_ascii()
    input = _to_array(<<-'INPUT')
      Björk
      Björn Ulvaeus & Benny Andersson
      Ultra-Lounge, Vol. 5: Wild, Cool & Swingin'
      Better That U Leave (with Lea-Lorién) - EP
      Michael Bublé & Chris Botti
      Meshell N'degeocello
      N'dea Davenport
      Salomé de Bahia
      Shèna
      Stéphane Pompougnac
      Ultra Naté
      Clémentine
      Déja Vu/Tasmin
      Ghostland/Natacha Atlas/Sinéad O'Connor
      Håkan Lidbo
      Isolée
    INPUT

    output = _to_array(<<-'OUTPUT')
      Bjoerk
      Bjoern Ulvaeus & Benny Andersson
      Ultra-Lounge, Vol. 5: Wild, Cool & Swingin'
      Better That U Leave (with Lea-Lorien) - EP
      Michael Buble & Chris Botti
      Meshell N'degeocello
      N'dea Davenport
      Salome de Bahia
      Shena
      Stephane Pompougnac
      Ultra Nate
      Clementine
      Deja Vu/Tasmin
      Ghostland/Natacha Atlas/Sinead O'Connor
      Hakan Lidbo
      Isolee
    OUTPUT

    assert_equal input.length,
                 output.length,
                 "Expected # input (#{input.length}) == # results (#{output.length})"

    input.each_with_index do |instr, index|
      outstr = output[index]

      ascii_text = instr.as_ascii

      assert_equal ascii_text,
                   outstr,
                   "TEXT |#{instr}|\nEXPECTED |#{outstr}|\nGOT |#{ascii_text}|"
      end
  end

  def test_string_reduce()
    input = _to_array(<<-'INPUT')
      |Sing It Back [BMR Clubcut mix]|
      Stars Above Us (Eric Kupper Ray)
      Rise (feat. Michelle Shellers) (Bini & Martini vocal mix)
      [Untitled]
    INPUT

    output = _to_array(<<-'OUTPUT')
      Sing It Back BMR Clubcut mix
      Stars Above Us Eric Kupper Ray
      Rise feat Michelle Shellers Bini Martini vocal mix
      Untitled
    OUTPUT

    assert_equal input.length,
                 output.length,
                 "Expected # input (#{input.length}) == # results (#{output.length})"

    output_ws = _to_array(<<-'OUTPUT_WS')
      Sing_It_Back_BMR_Clubcut_mix
      Stars_Above_Us_Eric_Kupper_Ray
      Rise_feat_Michelle_Shellers_Bini_Martini_vocal_mix
      Untitled
    OUTPUT_WS

    assert_equal output.length,
                 output_ws.length,
                 "Expected # output (#{output.length}) == # WS results (#{output_ws.length})"

    input.each_with_index do |instr, index|
      outstr = output[index]
      outstr_ws = output_ws[index]

      reduction = instr.reduce
      reduction_ws = instr.reduce_ws

      assert_equal reduction,
                   outstr,
                   "TEXT |#{instr}|\nEXPECTED |#{outstr}|\nGOT |#{reduction}|"

      assert_equal reduction_ws,
                   outstr_ws,
                   "TEXT |#{instr}|\nEXPECTED |#{outstr_ws}|\nGOT |#{reduction_ws}|"
      end

  end

  def test_symbol_reduce()
    input = _to_array(<<-'INPUT')
      |Sing It Back [BMR Clubcut mix]|
      Stars Above Us (Eric Kupper Ray)
      Rise (feat. Michelle Shellers) (Bini & Martini vocal mix)
      Rise__(feat.__Michelle__Shellers)|(Bini__&__Martini__vocal__mix)
      [__Untitled__]
    INPUT

    output = _to_array(<<-'OUTPUT')
      sing_it_back_bmr_clubcut_mix
      stars_above_us_eric_kupper_ray
      rise_feat_michelle_shellers_bini_martini_vocal_mix
      rise_feat_michelle_shellers_bini_martini_vocal_mix
      untitled
    OUTPUT

    assert_equal input.length,
                 output.length,
                 "Expected # input (#{input.length}) == # results (#{output.length})"

    input.each_with_index do |instr, index|
      insym = instr.to_sym

      outsym = output[index].to_sym

      reduction = insym.reduce

      assert_equal reduction,
                   outsym,
                   "TEXT |#{insym}|\nEXPECTED |#{outsym}|\nGOT |#{reduction}|"
    end

  end

  def _to_array(str)
    (str.split /\n/).map { |s| s.sub! /^\s+/, '' }
  end

end
