# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

module RedmineDmsf
  module Macros

    Redmine::WikiFormatting::Macros.register do

      # dmsf - link to a document
      desc "Wiki link to DMSF file:\n\n" +
               "{{dmsf(file_id [, title [, revision_id]])}}\n\n" +
           "_file_id_ / _revision_id_ can be found in the link for file/revision download."
      macro :dmsf do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if args[2].blank?
          revision = file.last_revision
        else
          revision = DmsfFileRevision.find args[2]
          if revision.dmsf_file != file
            raise ActiveRecord::RecordNotFound
          end
        end
        unless User.current&.allowed_to?(:view_dmsf_files, file.project, { id: file.id })
          raise l(:notice_not_authorized)
        end
        title = args[1].present? ?  args[1] : file.title
        title.gsub! /\A"|"\z/, '' # Remove apostrophes
        title.gsub! /\A'|'\z/, ''
        title = file.title if title.empty?
        url = view_dmsf_file_url(id: file.id, download: args[2])
        link_to h(title), url, target: '_blank', title: h(revision.tooltip),
          'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{url}"
      end

      # dmsff - link to a folder
      desc "Wiki link to DMSF folder:\n\n" +
               "{{dmsff([folder_id [, title]])}}\n\n" +
           "_folder_id_ can be found in the link for folder opening. Without arguments return link to main folder 'Documents'"
      macro :dmsff do |obj, args|
        if args.length < 1
          if User.current.allowed_to?(:view_dmsf_folders, @project) && @project.module_enabled?(:dmsf)
            return link_to l(:link_documents), dmsf_folder_url(@project)
          else
            raise l(:notice_not_authorized)
          end
        else
          folder = DmsfFolder.visible.find args[0]
          if User.current&.allowed_to?(:view_dmsf_folders, folder.project)
            title = args[1] ?  args[1] : folder.title
            title.gsub! /\A"|"\z/, '' # Remove leading and trailing apostrophe
            title.gsub! /\A'|'\z/, ''
            title = folder.title if title.empty?
            link_to h(title), dmsf_folder_url(folder.project, folder_id: folder)
          else
            raise l(:notice_not_authorized)
          end
        end
      end

      # dmsfd - link to the document's details
      desc "Wiki link to DMSF document details:\n\n" +
               "{{dmsfd(document_id [, title])}}\n\n" +
           "_document_id_ can be found in the document's details."
      macro :dmsfd do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          title = args[1].present? ?  args[1] : file.title
          title.gsub! /\A"|"\z/, '' # Remove leading and trailing apostrophe
          title.gsub! /\A'|'\z/, ''
          link_to h(title), dmsf_file_path(id: file)
        else
          raise l(:notice_not_authorized)
        end
      end

      # dmsfdesc - text referring to the document's description
      desc "Text referring to DMSF document description:\n\n" +
             "{{dmsfdesc(document_id)}}\n\n" +
             "_document_id_ can be found in the document's details."
      macro :dmsfdesc do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          textilizable file.description
        else
          raise l(:notice_not_authorized)
        end
      end

      # dmsfversion - text referring to the document's version
      desc "Text referring to DMSF document version:\n\n" +
             "{{dmsfversion(document_id)}}\n\n" +
             "_document_id_ can be found in the document's details."
      macro :dmsfversion do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          textilizable file.version
        else
          raise l(:notice_not_authorized)
        end
      end

      # dmsflastupdate - text referring to the document's last update date
      desc "Text referring to DMSF document last update date:\n\n" +
             "{{dmsflastupdate(document_id)}}\n\n" +
             "_document_id_ can be found in the document's details."
      macro :dmsflastupdate do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          textilizable format_time(file.last_revision.updated_at)
        else
          raise l(:notice_not_authorized)
        end
      end

      # dmsft - link to the document's content preview
      desc "Text referring to DMSF text document content:\n\n" +
               "{{dmsft(file_id, lines_count)}}\n\n" +
           "_file_id_ can be found in the document's details. _lines_count_ indicates quantity of lines to show."
      macro :dmsft do |obj, args|
        raise ArgumentError if args.length < 2 # Requires file id and lines number
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          file.text_preview(args[1]).gsub("\n", '<br/>').html_safe
        else
          raise l(:notice_not_authorized)
        end
      end

      # dmsf_image - link to an image
      desc "Wiki DMSF image:\n\n" +
                 "{{dmsf_image(file_id)}}\n" +
                 "{{dmsf_image(file_id, size=50%)}} -- with size 50%\n" +
                 "{{dmsf_image(file_id, size=300)}} -- with size 300\n" +
                 "{{dmsf_image(file_id, height=300)}} -- with height (auto width)\n" +
                 "{{dmsf_image(file_id, width=300)}} -- with width (auto height)\n" +
                 "{{dmsf_image(file_id, size=640x480)}} -- with size 640x480"
      macro :dmsf_image do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        file = DmsfFile.visible.find args[0]
        unless User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise l(:notice_not_authorized)
        end
        raise 'Not supported image format' unless file.image?
        url = view_dmsf_file_url(file)
        if size&.include?('%')
          image_tag url, alt: file.title, width: size, height: size
        elsif height
          image_tag url, alt: file.title, width: 'auto', height: height
        elsif width
          image_tag url, alt: file.title, width: width, height: 'auto'
        else
          image_tag url, alt: file.title, size: size
        end
      end

      # dmsf_video - link to a video
      desc "Wiki DMSF video:\n\n" +
               "{{dmsf_video(file_id)}}\n" +
               "{{dmsf_video(file_id, size=50%)}} -- with size 50%\n" +
               "{{dmsf_video(file_id, size=300)}} -- with size 300x300\n" +
               "{{dmsf_video(file_id, height=300)}} -- with height (auto width)\n" +
               "{{dmsf_video(file_id, width=300)}} -- with width (auto height)\n" +
               "{{dmsf_video(file_id, size=640x480)}} -- with size 640x480"
      macro :dmsf_video do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        file = DmsfFile.visible.find args[0]
        unless User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise l(:notice_not_authorized)
        end
        raise 'Not supported video format' unless file.video?
        url = view_dmsf_file_url(file)
        if size&.include?('%')
          video_tag url, controls: true, alt: file.title, width: size, height: size
        elsif height
          video_tag url, controls: true, alt: file.title, width: 'auto', height: height
        elsif width
          video_tag url, controls: true, alt: file.title, width: width, height: 'auto'
        else
          video_tag url, controls: true, alt: file.title, size: size
        end
      end

      # dmsftn - link to an image thumbnail
      desc "Wiki DMSF thumbnail:\n\n" +
                 "{{dmsftn(file_id)}} -- with default height 200 (auto width)\n" +
                 "{{dmsftn(file_id, size=300)}} -- with size 300x300\n" +
                 "{{dmsftn(file_id, height=300)}} -- with height (auto width)\n" +
                 "{{dmsftn(file_id, width=300)}} -- with width (auto height)\n" +
                 "{{dmsftn(file_id, size=640x480)}} -- with size 640x480"
      macro :dmsftn do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        file = DmsfFile.visible.find args[0]
        unless User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise l(:notice_not_authorized)
        end
        raise 'Not supported image format' unless file.image?
        url = view_dmsf_file_url(file)
        if size
          img = image_tag(url, alt: file.title, size: size)
        elsif height
          img = image_tag(url, alt: file.title, width: 'auto', height: height)
        elsif width
          img = image_tag(url, alt: file.title, width: width, height: 'auto')
        else
          img = image_tag(url, alt: file.title, width: 'auto', height: 200)
        end
        link_to img, url, target: '_blank', title: h(file.last_revision.try(:tooltip)),
          'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{url}"
      end

      # dmsfw - link to a document's approval workflow status
      desc "Text referring to DMSF document's approval workflow status:\n\n" +
               "{{dmsfw(file_id)}}\n\n" +
           "_file_id_ can be found in the document's details."
      macro :dmsfw do |obj, args|
        raise ArgumentError if args.length < 1 # Requires file id
        file = DmsfFile.visible.find args[0]
        if User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise ActiveRecord::RecordNotFound unless file.last_revision
          file.last_revision.workflow_str(false)
        else
          raise l(:notice_not_authorized)
        end
      end

    end

  end
end
