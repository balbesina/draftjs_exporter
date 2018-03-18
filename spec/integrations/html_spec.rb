# frozen_string_literal: true
require 'spec_helper'
require 'draftjs_exporter/html'
require 'draftjs_exporter/entities/link'

RSpec.describe DraftjsExporter::HTML do
  subject(:mapper) do
    described_class.new(
      entity_decorators: {
        'LINK' => DraftjsExporter::Entities::Link.new(className: 'foobar-baz')
      },
      block_map: {
        'header-one' => { element: 'h1' },
        'unordered-list-item' => {
          element: 'li',
          wrapper: ['ul', { className: 'public-DraftStyleDefault-ul' }]
        },
        'unstyled' => { element: 'div' }
      },
      style_map: {
        :ITALIC.to_s => {fontStyle: 'italic'},
        :UNDERLINE.to_s => {textDecoration: 'underline'},
        :STRIKETHROUGH.to_s => {textDecoration: 'line-through'}
      }
    )
  end

  describe '#call' do
    let(:input) { nil }
    let(:options) { {} }
    subject { mapper.call(input, options) }

    context 'with different blocks' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: '5s7g9',
              text: 'Header',
              type: 'header-one',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            },
            {
              key: 'dem5p',
              text: 'some paragraph text',
              type: 'unstyled',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            }
          ]
        }
      end

      it 'decodes the content_state to html' do
        expected_output = <<-OUTPUT.strip
<h1>Header</h1><div>some paragraph text</div>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'with inline styles' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'dem5p',
              text: 'some paragraph text',
              type: 'unstyled',
              depth: 0,
              inlineStyleRanges: [
                {
                  offset: 0,
                  length: 4,
                  style: 'ITALIC'
                }
              ],
              entityRanges: []
            }
          ]
        }
      end

      it 'decodes the content_state to html' do
        expected_output = <<-OUTPUT.strip
<div>
<span style="font-style: italic;">some</span> paragraph text</div>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'with entities' do
      let(:input) do
        {
          entityMap: {
            '0' => {
              type: 'LINK',
              mutability: 'MUTABLE',
              data: {
                url: 'http://example.com'
              }
            }
          },
          blocks: [
            {
              key: 'dem5p',
              text: 'some paragraph text',
              type: 'unstyled',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: [
                {
                  offset: 5,
                  length: 9,
                  key: 0
                }
              ]
            }
          ]
        }
      end

      it 'decodes the content_state to html' do
        expected_output = <<-OUTPUT.strip
<div>some <a href="http://example.com" class="foobar-baz">paragraph</a> text</div>
        OUTPUT

        is_expected.to eq(expected_output)
      end

      context 'with deeply_symbolized entities' do
        let(:input) do
          {
            entityMap: {
              :'0' => {
                type: 'LINK',
                mutability: 'MUTABLE',
                data: {
                  url: 'http://example.com'
                }
              }
            },
            blocks: [
              {
                key: 'dem5p',
                text: 'some paragraph text',
                type: 'unstyled',
                depth: 0,
                inlineStyleRanges: [],
                entityRanges: [
                  {
                    offset: 5,
                    length: 9,
                    key: 0
                  }
                ]
              }
            ]
          }
        end

        it 'decodes the content_state to html' do
          expected_output = <<-OUTPUT.strip
<div>some <a href="http://example.com" class="foobar-baz">paragraph</a> text</div>
          OUTPUT

          is_expected.to eq(expected_output)
        end
      end


      context 'when entities cross over' do
        let(:input) do
          {
            entityMap: {
              '0' => {
                type: 'LINK',
                mutability: 'MUTABLE',
                data: {
                  url: 'http://foo.example.com'
                }
              },
              '1' => {
                type: 'LINK',
                mutability: 'MUTABLE',
                data: {
                  url: 'http://bar.example.com'
                }
              }
            },
            blocks: [
              {
                key: 'dem5p',
                text: 'some paragraph text',
                type: 'unstyled',
                depth: 0,
                inlineStyleRanges: [],
                entityRanges: [
                  {
                    offset: 5,
                    length: 9,
                    key: 0
                  },
                  {
                    offset: 2,
                    length: 9,
                    key: 1
                  }
                ]
              }
            ]
          }
        end

        it 'throws an error' do
          expect { subject }.to raise_error(DraftjsExporter::InvalidEntity)
        end
      end
    end

    context 'with wrapped blocks' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'dem5p',
              text: 'item1',
              type: 'unordered-list-item',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            },
            {
              key: 'dem5p',
              text: 'item2',
              type: 'unordered-list-item',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            }
          ]
        }
      end

      it 'decodes the content_state to html' do
        expected_output = <<-OUTPUT.strip
<ul class="public-DraftStyleDefault-ul">\n<li>item1</li>\n<li>item2</li>\n</ul>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'with UTF-8 encoding' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'ckf8d',
              text: 'Russian: Привет, мир!',
              type: 'unordered-list-item',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: [],
              data: {}
            },
            {
              key: 'fi809',
              text: 'Japanese: 曖昧さ回避',
              type: 'unordered-list-item',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: [],
              data: {}
            }
          ]
        }
      end
      let(:options) { {encoding: 'UTF-8'} }

      it 'leaves non-latin letters as-is' do
        expected_output = <<-OUTPUT.strip
          <ul class=\"public-DraftStyleDefault-ul\">\n<li>Russian: Привет, мир!</li>\n<li>Japanese: 曖昧さ回避</li>\n</ul>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'when inline color' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'ckf8d',
              text: 'Red Text',
              type: 'header-one',
              depth: 0,
              inlineStyleRanges:[{offset:0,length:3,style:"color-rgb(184,49,47)"}],
              entityRanges: [],
              data: {}
            }
          ]
        }
      end

      it 'should correctly process' do
        expected_output = <<-OUTPUT.strip
          <h1>\n<span style="color: rgb(184,49,47);">Red</span> Text</h1>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'when data styles' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'ckf8d',
              text: 'centered',
              type: 'header-one',
              depth: 0,
              inlineStyleRanges:[],
              entityRanges: [],
              data: {"text-align" => 'center'}
            }
          ]
        }
      end

      it 'should correctly process' do
        expected_output = <<-OUTPUT.strip
          <h1 style="text-align: center;">centered</h1>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end

    context 'when different styles with same htmlStyle' do
      let(:input) do
        {
          entityMap: {},
          blocks: [
            {
              key: 'ckf8d',
              text: 'StrikeAndUnderline',
              type: 'header-one',
              depth: 0,
              inlineStyleRanges:[
                {offset:0, length:18, style:'UNDERLINE'},
                {offset:0, length:18, style:'STRIKETHROUGH'},
              ],
              entityRanges: [],
              data: {}
            }
          ]
        }
      end

      it 'should correctly process' do
        expected_output = <<-OUTPUT.strip
          <h1>\n<span style="text-decoration: underline line-through;">StrikeAndUnderline</span></h1>
        OUTPUT

        is_expected.to eq(expected_output)
      end
    end
  end
end
