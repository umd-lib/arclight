# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Indexing Custom Document', type: :feature do
  subject do
    Arclight::CustomDocument.from_xml(File.read('spec/fixtures/ead/alphaomegaalpha.xml'))
  end

  context 'solrizer' do
    let(:doc) { subject.to_solr }

    it '#level' do
      expect(doc['level_ssm'].first).to eq 'collection'
      expect(doc['level_sim'].first).to eq 'Collection'
    end

    it '#unitid' do
      expect(doc['unitid_ssm'].first).to eq 'MS C 271'
    end

    it '#repository' do
      expect(doc['repository_ssm'].first).to eq '1118 Badger Vine Special Collections'
      expect(doc['repository_sim'].first).to eq '1118 Badger Vine Special Collections'
    end

    it '#creator' do
      expect(doc['creator_ssm'].first).to eq 'Alpha Omega Alpha'
      expect(doc['creator_sim'].first).to eq 'Alpha Omega Alpha'
    end

    it '#extent' do
      expect(doc['extent_ssm'].first).to match(/^15\.0 linear feet/)
    end

    it '#unitdate' do
      expect(doc['unitdate_ssm'].first).to eq '1894-1992'
    end

    it '#accessrestrict' do
      expect(doc['accessrestrict_ssm'].first).to eq 'No restrictions on access.'
    end

    it '#scopecontent' do
      expect(doc['scopecontent_ssm'].first).to match(/^Correspondence, documents/)
    end

    it '#names' do
      expect(doc['names_sim']).to include 'Root, William Webster, 1867-1932'
    end

    it '#access_subjects' do
      expect(doc['access_subjects_sim']).to include 'Fraternizing'
    end

    describe '#date_range' do
      it 'includes an array of all the years in a particular unit-date range described in YYYY/YYYY format' do
        date_range_field = doc['date_range_sim']
        expect(doc['unitdate_ssm']).to eq ['1894-1992'] # the field the range is derived from
        expect(date_range_field).to be_an Array
        expect(date_range_field.length).to eq 99
        expect(date_range_field.first).to eq '1894'
        expect(date_range_field.last).to eq '1992'
      end

      # We don't have EADs in our fixtures that exhibit the following behaviors
      it 'is nil for non normal dates'
      it 'handles normal unitdates formatted as YYYY/YYYY when the years are the same'
      it 'handles normal unitdates formatted as YYYY'
    end
  end
end