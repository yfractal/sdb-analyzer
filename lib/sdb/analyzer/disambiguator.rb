# frozen_string_literal: true

require 'json'

module Sdb
  module Analyzer
    class Disambiguator
      def initialize(roots)
        @roots = roots
      end

      def disambiguate
        roots = remove_invalid(@roots)

        roots.map do |root|
          disambiguate_node(root)
        end
      end

      private

      # fold single child node
      def do_disambiguate_node(parent)
        current = parent
        prev = nil

        while current.children.count == 1
          prev = current
          current = current.children.first
        end

        if prev
          parent.children = [prev]
          prev.children = current.children

          current.children
        else
          # the first child has multiple children, do not fold
          parent.children
        end
      end

      # Disambiguator
      # node is Sdb::Analyzer::FrameAnalyzer::IseqNode
      def disambiguate_node(parent)
        children = do_disambiguate_node(parent)

        children.each do |child|
          disambiguate_node(child)
        end

        parent
      end

      def valid_child?(child)
        if child.iseq.label == nil && child.iseq.path == nil
          return false
        end

        if child.iseq.path.include?('sdb/')
          return false
        end

        true
      end

      def do_remove_invalid_children(children)
        new_children = []

        children.each do |child|
          if valid_child?(child)
            new_children << child
          else
            new_children += do_remove_invalid_children(child.children)
          end
        end

        new_children
      end

      def do_remove_invalid(node)
        node.children = do_remove_invalid_children(node.children)

        node.children.each do |child|
          do_remove_invalid(child)
        end

        node
      end

      def remove_invalid(roots)
        new_roots = []
        roots.each do |root|
          if valid_child?(root)
            new_roots << do_remove_invalid(root)
          else
            new_roots += remove_invalid(root.children)
          end
        end

        new_roots
      end
    end
  end
end
