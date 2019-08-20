# frozen_string_literal: true

require 'spec_helper'

describe 'EAD 2 traject indexing', type: :feature do
  subject(:result) do
    indexer.map_record(record)
  end

  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new.tap do |i|
      i.load_config_file(Arclight::Engine.root.join('lib/arclight/traject/ead2_config.rb'))
    end
  end
  let(:fixture_path) do
    Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'sul-spec', 'a0011.xml')
  end
  let(:fixture_file) do
    File.read(fixture_path)
  end
  let(:nokogiri_reader) do
    Traject::NokogiriReader.new(fixture_file.to_s, {})
  end
  let(:records) do
    nokogiri_reader.to_a
  end
  let(:record) do
    records.first
  end

  before do
    ENV['REPOSITORY_ID'] = nil
  end

  after do # ensure we reset these otherwise other tests will fail
    ENV['REPOSITORY_ID'] = nil
  end

  describe 'solr fields' do
    before do
      ENV['REPOSITORY_ID'] = 'sul-spec'
    end

    it 'id' do
      expect(result['id'].first).to eq 'a0011-xml'
      expect(result['ead_ssi'].first).to eq 'a0011-xml'
    end
    it 'title' do
      %w[title_ssm title_teim].each do |field|
        expect(result[field]).to include 'Stanford University student life photograph album'
      end
      expect(result['normalized_title_ssm']).to include 'Stanford University student life photograph album, circa 1900-1906'
    end
    it 'level' do
      expect(result['level_ssm']).to eq ['collection']
      expect(result['level_sim']).to eq ['Collection']
    end
    it 'dates' do
      expect(result['normalized_date_ssm']).to include 'circa 1900-1906'
      expect(result['unitdate_bulk_ssim']).to be_nil
      expect(result['unitdate_inclusive_ssim']).to include 'circa 1900-1906'
      expect(result['unitdate_other_ssim']).to be_nil
    end
    it 'repository' do
      %w[repository_sim repository_ssm].each do |field|
        expect(result[field]).to include 'Stanford University Libraries. Special Collections and University Archives'
      end
    end
    describe 'components' do
      it 'id' do
        expect(result['components'].first).to include 'id' => ['a0011-xmlaspace_ref6_lx4']
      end
      it 'repository' do
        %w[repository_sim repository_ssm].each do |field|
          expect(result['components'].first[field]).to include 'Stanford University Libraries. Special Collections and University Archives'
        end
      end
    end
  end

  describe 'large component list' do
    let(:fixture_path) do
      Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'sample', 'large-components-list.xml')
    end

    it 'selects the components' do
      expect(result['components'].length).to eq 404
    end
  end

  describe 'for control access elements' do
    let(:fixture_path) do
      Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'nlm', 'alphaomegaalpha.xml')
    end

    it 'indexes the values as controlled vocabulary terms' do
      expect(result).to include 'components'
      expect(result['components']).not_to be_empty
      first_component = result['components'].first

      expect(first_component).to include 'access_subjects_ssim'
      expect(first_component['access_subjects_ssim']).to contain_exactly(
        'Alpha Omega Alpha',
        'Bierring, Walter L. (Walter Lawrence), 1868-1961',
        'Fraternizing',
        'Medicine',
        'Minutes',
        'Mindanao Island (Philippines)',
        'Owner of the reel of yellow nylon rope',
        'Photographs',
        'Popes Creek (Md.)',
        'Records',
        'Robertson\'s Crab House',
        'Root, William Webster, 1867-1932',
        'Societies',
        'Speeches'
      )

      expect(first_component).to include 'access_subjects_ssm'
      expect(first_component['access_subjects_ssm']).to contain_exactly(
        'Alpha Omega Alpha',
        'Bierring, Walter L. (Walter Lawrence), 1868-1961',
        'Fraternizing',
        'Medicine',
        'Minutes',
        'Mindanao Island (Philippines)',
        'Owner of the reel of yellow nylon rope',
        'Photographs',
        'Popes Creek (Md.)',
        'Records',
        'Robertson\'s Crab House',
        'Root, William Webster, 1867-1932',
        'Societies',
        'Speeches'
      )
    end

    context 'with nested controlaccess elements' do
      let(:fixture_path) do
        Arclight::Engine.root.join('spec', 'fixtures', 'ead', 'ncaids544-id-test.xml')
      end

      it 'indexes the values as controlled vocabulary terms' do
        expect(result).to include 'components'
        expect(result['components']).not_to be_empty
        first_component = result['components'].first

        expect(first_component).to include 'access_subjects_ssim'
        expect(first_component['access_subjects_ssim']).to contain_exactly(
          'Acquired Immunodeficiency Syndrome',
          'African Americans',
          'Homosexuality',
          'Human Immunodeficiency Virus',
          'Public Health',
          'United States. Presidential Commission on the Human Immunodeficiency Virus  Epidemic'
        )

        expect(first_component).to include 'access_subjects_ssm'
        expect(first_component['access_subjects_ssm']).to contain_exactly(
          'Acquired Immunodeficiency Syndrome',
          'African Americans',
          'Homosexuality',
          'Human Immunodeficiency Virus',
          'Public Health',
          'United States. Presidential Commission on the Human Immunodeficiency Virus  Epidemic'
        )
      end
    end
  end
end