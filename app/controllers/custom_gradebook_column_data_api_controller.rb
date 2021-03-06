#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# @API Custom Gradebook Columns
# @subtopic Custom Gradebook Column Data
#
# Column Datum objects contain the entry for a column for each user.
#
# @object Column Datum
#    {
#      "content": "Nut allergy",
#
#      "user_id": 2
#    }
class CustomGradebookColumnDataApiController < ApplicationController
  before_filter :require_context, :require_user

  include Api::V1::CustomGradebookColumn

  # @API List entries for a column
  #
  # This does not list entries for students without associated data.
  #
  # @returns [Column Datum]
  def index
    col = @context.custom_gradebook_columns.active.find(params[:id])

    if authorized_action? col, @current_user, :read
      scope = col.custom_gradebook_column_data.where(user_id: allowed_user_ids)

      data = Api.paginate(scope, self,
                          api_v1_course_custom_gradebook_column_data_url(@context, col))

      render :json => data.map { |d|
        custom_gradebook_column_datum_json(d, @current_user, session)
      }
    end
  end

  # @API Update column data
  #
  # Set the content of a custom column
  #
  # @argument column_data[content] [String]
  #   Column content.  Setting this to blank will delete the datum object.
  #
  # @returns Column Datum
  def update
    user = allowed_users.where(:id => params[:user_id]).first
    raise ActiveRecord::RecordNotFound unless user

    column = @context.custom_gradebook_columns.active.find(params[:id])
    datum   = column.custom_gradebook_column_data.where(user_id: user).first
    datum ||= column.custom_gradebook_column_data.build.tap { |d|
      d.user_id = user.id
    }
    if authorized_action? datum, @current_user, :update
      datum.attributes = params[:column_data]
      if datum.content.blank?
        datum.destroy
        render :json => custom_gradebook_column_datum_json(datum, @current_user, session)
      elsif datum.save
        render :json => custom_gradebook_column_datum_json(datum, @current_user, session)
      else
        render :json => datum.errors
      end
    end
  end

  def allowed_users
    @context.students_visible_to(@current_user)
  end
  private :allowed_users

  def allowed_user_ids
    allowed_users.pluck(:id)
  end
  private :allowed_user_ids
end
