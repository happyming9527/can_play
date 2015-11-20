require 'ror_hack'
require 'consul'
require 'cancancan'
require 'can_play/config'
require 'can_play/class_method'
require 'can_play/railtie'

module CanPlay

  singleton_attr_accessor :resources, :override_resources,
                          :override_code, :groups

  self.resources          = []
  self.override_resources = {}.with_indifferent_access
  self.override_code      = nil
  self.groups        = []

  module_function

  def included(base)
    base.extend ClassMethods
  end

  def find_by_name_and_code(name, code)
    resource = CanPlay.override_resources[code].p2a.find { |r| r.name.to_s == name.to_s }
    resource || CanPlay.resources.find { |r| r.name.to_s == name.to_s }
  end

  def conjunct_resources(&block)
    resources = CanPlay.override_resources[CanPlay.override_code].p2a + CanPlay.resources
    resources = resources.uniq { |i| i.name }
    resources = resources.select(&block) if block
    resources
  end

  def grouped_resources(&block)
    conjunct_resources(&block).multi_group_by(:my_module_name, :group)
  end

  def splat_grouped_resources(&block)
    conjunct_resources(&block).group_by(&:group)
  end

  def grouped_resources_with_chinese_desc(&block)
    grouped_resources(&block).tap do |e|
      e.each do |i, v|
        v.each do |group, resources|
          group.chinese_desc = begin
            name = I18n.t("can_play.class_name.#{group.name.to_s.singularize}", default: '')
            name = group.klass.model_name.human if name.blank?
            name
          end
          resources.each do |resource|
            resource.chinese_desc = I18n.t("can_play.authority_name.#{group.name.to_s.singularize}.#{resource.verb}", default: '').presence || I18n.t("can_play.authority_name.common.#{resource.verb}")
          end
        end
        v.rehash
      end
    end
  end

  def splat_grouped_resources_with_chinese_desc(&block)
    splat_grouped_resources(&block).tap do |i|
      i.each do |group, resources|
        group[:chinese_desc] = begin
          name = I18n.t("can_play.class_name.#{group.name.singularize}", default: '')
          name = group.klass.model_name.human if name.blank?
          name
        end
        resources.each do |resource|
          resource[:chinese_desc] = I18n.t("can_play.authority_name.#{group[:name].singularize}.#{resource[:verb]}", default: '').presence || I18n.t("can_play.authority_name.common.#{resource[:verb]}")
        end
      end
      i.rehash
    end
  end
end

require 'can_play/resource'
require 'can_play/power'
require 'can_play/play_resource_object'
require 'can_play/controller'
require 'can_play/ability'