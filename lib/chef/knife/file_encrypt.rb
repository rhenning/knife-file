#
# Author:: Christian Paredes <cp@redbluemagenta.com>
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Knife
    class FileEncrypt < Knife

      deps do
        require 'chef/json_compat'
        require 'chef/encrypted_data_bag_item'
        require 'chef/knife/core/object_loader'
      end

      banner "knife file encrypt FILE [options]"

      option :secret,
      :short => "-s SECRET",
      :long  => "--secret ",
      :description => "The secret key to use to encrypt data bag item values"

      option :secret_file,
      :long => "--secret-file SECRET_FILE",
      :description => "A file containing the secret key to use to encrypt data bag item values"

      def read_secret
        if config[:secret]
            config[:secret]
        else
            Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        end
      end

      def use_encryption
        if config[:secret] && config[:secret_file]
            stdout.puts "please specify only one of --secret, --secret-file"
            exit(1)
        end
        config[:secret] || config[:secret_file]
      end

      def loader
        @loader ||= Chef::Knife::Core::ObjectLoader.new(Chef::DataBagItem, ui)
      end

      def run
        if @name_args.size != 1
            stdout.puts opt_parser
            exit(1)
        end
        @item_path = @name_args[0]
        if ! use_encryption
            stdout.puts opt_parser
            exit(1)
        end
        secret = read_secret
        item = loader.object_from_file(@item_path)
        item = Chef::EncryptedDataBagItem.encrypt_data_bag_item(item, secret)
        output(format_for_display(item.to_hash))
      end
    end
  end
end
