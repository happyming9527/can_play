require 'ror_hack'
require 'consul'
require 'cancancan'
require 'modularity'

module CanPlay
  mattr_accessor :resources, :override_resources, :override_code
  self.override_code      = nil
  self.resources          = []
  self.override_resources = {}.with_indifferent_access

  class << self
    def included(base)
      base.class_eval <<-RUBY
        singleton_attr_accessor(:groups, :current_group, :module_name)
        self.groups        = []
        self.current_group = nil
        self.module_name = ''
      RUBY
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
      conjunct_resources(&block).multi_group_by(:module_name, :group)
    end

    def splat_grouped_resources(&block)
      conjunct_resources(&block).multi_group_by(:group)
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

  module Config
    mattr_accessor :user_class_name, :role_class_name, :role_resources_relation_name, :super_roles, :role_judge_method
    self.user_class_name              = 'User'
    self.role_class_name              = 'Role'
    self.role_resources_relation_name = 'role_resources'
    self.super_roles                  = []
    self.role_judge_method            = 'role?'

    def self.setup
      yield self
    end
  end

  module ClassMethods

    class NameImportantOpenStruct < OpenStruct
      def eql?(another)
        self.name == another.name
      end
    end

    # 为每个 resource 添加一个 group, 方便管理
    def group(*args, &block)
      opts = args.extract_options!.with_indifferent_access
      clazz = args.first
      if clazz.is_a?(Module)
        name  = clazz.try(:table_name).presence || clazz.to_s.underscore.gsub('/', '_').pluralize
        group = NameImportantOpenStruct.new(name: name, klass: clazz)
      elsif clazz.blank? &&  opts.key?(:name)
        opts  = opts.with_indifferent_access
        group = NameImportantOpenStruct.new(name: opts.delete(:name).to_s, klass: opts.delete(:klass))
      else
        raise "group klass need set"
      end
      group.opts = OpenStruct.new opts
      self.groups << group
      self.groups        = groups.uniq(&:name)
      self.current_group = group
      block.call(group.klass)
      self.current_group = nil
    end

    def limit(name=nil, &block)
      raise "Need define group first" if current_group.nil?
      CanPlay::Power.power(name||current_group.name, &block)
    end

    def collection(verb_or_verbs, opts={}, &block)
      raise "Need define group first" if current_group.nil?
      opts = OpenStruct.new opts
      group    = current_group
      behavior = nil
      if block
        behavior = lambda do |user|
          # 在block定义的binding里，注入user这个变量。
          old_binding = block.binding
          old_binding.eval("user=nil;lambda {|v| user = v}").call(user)
          block.call_with_binding(old_binding)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'collection', behavior, opts)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'collection', behavior, opts)
      end
    end

    def member(verb_or_verbs, opts={}, &block)
      raise "Need define group first" if current_group.nil?
      opts = OpenStruct.new opts
      group    = current_group
      behavior = nil
      if block
        behavior = lambda do |user, obj|
          # 在block定义的binding里，注入user这个变量。
          old_binding = block.binding
          old_binding.eval("user=nil;lambda {|v| user = v}").call(user)
          block.call_with_binding(old_binding, obj)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'member', behavior, opts)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'member', behavior, opts)
      end
    end

    def add_resource(group, verb, object, type, behavior, opts)
      name     = "#{verb}_#{group.name}"
      resource = OpenStruct.new(
        module_name: module_name,
        name:        name,
        group:       group,
        verb:        verb,
        object:      object,
        type:        type,
        behavior:    behavior,
        opts:        opts
      )
      CanPlay.resources.keep_if { |i| i.name != name }
      CanPlay.resources << resource
    end
  end

  module Override
    as_trait do |code|
      extend ClassMethods
      singleton_attr_accessor(:groups, :current_group, :module_name)
      self.groups        = []
      self.current_group = nil
      self.module_name   = ''

      define_singleton_method(:limit) do |name=nil, &block|
        raise "Need define group first" if current_group.nil?
        method_name = name ? "#{name}_evaluate_in_#{code}_scope" : "#{current_group.name}_evaluate_in_#{code}_scope"
        Power.power(method_name, &block)
      end

      define_singleton_method(:add_resource) do |group, verb, object, type, behavior, opts|
        super(group, verb, object, type, behavior, opts) and return if code.blank?
        CanPlay.override_resources[code] ||= []
        name                             = "#{verb}_#{group.name}"
        resource                         = OpenStruct.new(
          module_name: module_name,
          name:        name,
          group:       group,
          verb:        verb,
          object:      object,
          type:        type,
          behavior:    behavior,
          opts:        opts
        )
        CanPlay.override_resources[code].keep_if { |i| i.name != name }
        CanPlay.override_resources[code] << resource
      end
    end
  end
end

require "can_play/power"
require "can_play/controller"
require "can_play/ability"
