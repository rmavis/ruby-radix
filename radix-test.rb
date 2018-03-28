=begin

The radix tree implemented by this class is one in which every node:
- at the top level indicates a word root, and
- at every level below that, indicates a word that can be built from
  that root.

The tree is represented as a hash. Every node (key) will contain
a subhash. If a key's subhash is empty, the branch stops there. So
the tree

    {
      "g" => {
        "roup" => {
          "er" => { },
          "ie" => {
            "s" => { }
          }
        }
      }
    }

contains the words 'group', 'grouper', 'groupie', and 'groupies'.

=end


class RadixTree


  def initialize
    @store = { }
  end

  attr_reader :store



  def add( string )
    added = add_to_tree(@store, string)

    if added
      # puts "Added '#{string}' to tree:"
      # puts @store.to_s
    else
      # puts "Failed to add '#{string}' to tree:"
      # puts @store.to_s
    end
  end



  def del( string )
    deleted = remove_from_tree(@store, string)

    if deleted
      # puts "Deleted '#{string}' from tree:"
      # puts @store.to_s
    else
      # puts "Failed to delete '#{string}' from tree:"
      # puts @store.to_s
    end
  end



  def get( string )
    matches = match_string(@store, string)

    if matches.empty?
      # puts "Failed to match '#{string}'."
    else
      # puts "Matches for '#{string}':"
      # puts matches.to_s
      return matches
    end
  end




  protected


  def add_to_tree( tree, string )
    # puts "Adding '#{string}' to tree:"
    # puts tree.to_s

    if string.empty?
      # puts "Nothing to add!"
      return nil
 
    elsif tree.empty?
      # puts "Tree is empty!"
      tree[string] = { }
      return true

    else
      leaf = string
      branch = ''
      trunk = ''
      simdex = 0

      tree.each do |key,val|
        # Get the maximum similarity of the key.
        simdex = string.simdex(key)

        # If there is a match.
        if 0 < simdex
          trunk = key
          # `branch` is the new parent. When adding a string that is
          # a superstring of the parent, the trunk and branch will
          # be the same.
          branch = key[0, simdex]
          # puts "Found branch: #{branch}"
          # The leaf is the new child. This value will be empty in
          # cases when the `string` is a substring of the `key`. And
          # in those cases, that `branch` needs to become the new
          # parent.
          leaf = string.leaf(simdex)
          # And exit as soon as possible.
          break
        end
      end

      if branch.empty?
        # puts "No branch found."
        tree[leaf] = { }
        return true

      elsif branch != trunk
        # So if the parent (branch) and child (leaf) are the same
        # (as when adding a string that is a substring of an existing
        # string) then the old parent (trunk) must be transplanted
        # under the new one (sprout).
        sprout = trunk.leaf(simdex)  # [simdex, (trunk.length - 1)]
        # puts "Splitting `#{trunk}` branch into `#{branch}` and `#{leaf}`/`#{sprout}`."

        if sprout.empty?
          if leaf.empty?
            # When will this ever occur?
            puts "This should not be occurring. Branch (#{branch}) != Trunk (#{trunk}), sprout and leaf are empty."
            return nil
          else
            tree[branch] = { leaf => tree[trunk] }
          end
        else
          if leaf.empty?
            tree[branch] = { sprout => tree[trunk] }
          else
            tree[branch] = { sprout => tree[trunk], leaf => { } }
          end
        end

        tree.delete(trunk)
        return true

        # if ((leaf == sprout) && (!leaf.empty?))
        #   tree[branch] = { leaf => tree[trunk] }
        # elsif !leaf.empty?
        #   tree[branch] = { sprout => tree[trunk], leaf => { } }
        # else
        # end

        # tree.delete(trunk)
        # return true

      elsif !leaf.empty?
        # puts "#{string} (leaf #{leaf}) is a superstring of #{branch}"
        return add_to_tree(tree[branch], leaf)

      else
        # puts "Not recurring on branch '#{branch}' with empty leaf."
        return nil  # add_to_tree(tree[branch], leaf)
      end
    end
  end



  # Rules for matching:
  # - Run through the string. At the first match, start accruing.
  # - You should reach a point when the leaf equals the branch.
  # - When that occurs, push the accrue the rest of the branch and
  #   recursively prepend each parent to each child
  def match_string( tree, string )
    # puts "Checking for `#{string}` in tree (#{tree})."

    if tree.empty?
      # puts "Tree is empty, returning empty"
      return [ ]

    elsif string.empty?
      # puts "No search string, returning empty"
      return [ ]

    else
      matches = [ ]

      tree.each do |key,val|
        # puts "Checking for `#{string}` in `#{key}` branch."

        simdex = string.simdex(key)

        if 0 < simdex
          if string == key
            # puts "Matched full word! #{string} is #{key}"
            # matches = collect_keys(val, key).unshift(key)
            return collect_keys(val, key).unshift(key)
            # puts "Got matches: #{matches}"

          else
            leaf = string.leaf(simdex)
            # puts "Got leaf #{leaf}"

            check = match_string(val, leaf)
            # puts "Got check: #{check}"

            if !check.empty?
              # matches = (check.map { |m| key + m })
              return check.map { |m| key + m }
              # puts "New matches: #{matches}"
            end
          end

          # break

        else
          check = match_string(val, string)

          if !check.empty?
            matches += check
          end
        end
      end

      # if matches.empty?
      #   # puts "No matches (#{string})"
      # else
      #   # puts "Returning matches (#{string}): #{matches}"
      # end

      return matches
    end
  end



  def collect_keys( tree, string = '' )
    # puts "Collating: #{string} onto #{tree}"

    keys = [ ]

    tree.each do |key,val|
      col_key = string + key
      keys.push(col_key)

      if !val.empty?
        keys += collect_keys(val, col_key)
      end
    end

    return keys
  end



  # Rules for deletion:
  # - First, run through the string. You should reach a point when
  #   the leaf equals the branch.
  # - When you hit that point, if the branch is a leaf, then just
  #   delete the branch
  # - If not, then the branch names of the sub-branches need to be
  #   merged with the one to be deleted and brought to that one's
  #   level before it can be deleted.
  def remove_from_tree( tree, string )
    if tree.nil? || tree.empty?
      # puts "Tree is empty!"
      return nil

    elsif string.empty?
      # puts "No string given to remove."
      return nil

    else
      deleted = nil
      sprouts = { }

      tree.each do |key,val|
        # puts "Checking `#{key}` branch for '#{string}'."

        simdex = string.simdex(key)

        if 0 < simdex

          if key == string
            if val.empty?
              # puts "Deleting leaf branch '#{key}' (#{val.to_s})"
              tree.delete(key)
              deleted = true

            else
              # puts "Deleting branch '#{key}' but merging children."
              # This is problematic because it adds to the hash being
              # iterated on. #HERE
              sprouts[key] = [ ] if !sprouts.has_key?(key)
              val.each do |subkey,subval|
                # puts "Pushing #{key} branch into sprouts."
                sprouts[key].push({ subkey => subval })
                # tree[key + subkey] = subval
              end
              # tree.delete(key)
              deleted = true
            end

          else
            leaf = string.leaf(simdex)
            branch = key[0, simdex]
            # puts "Descending into branch '#{branch}' with '#{leaf}'"
            deleted = (deleted) ? deleted : remove_from_tree(tree[branch], leaf)
          end

        else
          deleted = (deleted) ? deleted : remove_from_tree(val, string)
          # deleted = remove_from_tree(val, string)
        end
      end

      if deleted.nil?
        # puts "No branch found for '#{string}'."

      else
        # puts "Sprouts: #{sprouts}"
        sprouts.each do |key,branches|
          branches.each do |branch|
            branch.each do |subkey,subval|
              # puts "#{key} + #{subkey} = #{subval}"
              tree[key + subkey] = subval
            end
          end
          tree.delete(key)
        end
        # puts "Deleted branch '#{string}' (tree: #{tree.to_s})."
      end

      return deleted
    end
  end


end





#
# Helper functions.
#

class String

  # SIMilarity inDEX. ha.
  def simdex( str )
    s = 0
    s += 1 while ((self[s]) && (self[s] == str[s]))
    return s
  end


  def leaf( n )
    return self[n, (self.length - n)]
  end

end







# rad = RadixTree.new


# # Addition.
# rad.add('groupies')
# rad.add('guppie')
# rad.add('loon')
# rad.add('groupie')
# rad.add('group')
# rad.add('group')
# rad.add('group')
# rad.add('grouper')

# rad.add('guppies')
# rad.add('guppiescene')
# rad.add('guppiescenesters')
# rad.add('guppiers')
# rad.add('guppiersers')

# rad.add('goon')
# rad.add('goons')
# rad.add('goonsquad')


# # Matching.
# rad.get('group')  # => ['group', 'grouper', 'groupie', 'groupies']
# rad.get('goon')  # => ['goon', 'goons', 'goonsquad']
# rad.get('fart')  # => [ ]
# rad.get('ie')  # => ['ie', 'ies']
# rad.get('s')  # => ['s', 'scene', 'scenesters', 'squad']


# Subtraction.
# rad.del('goonsquad')
# rad.del('guppie')
# rad.del('g')
# rad.del('farts')



=begin

{
  "g" => {
    "roup" => {
      "er" => { },
      "ie" => {
        "s" => { }
      }
    },
    "uppie" => {
      "s" => {
        "cene" => {
          "sters" => { }
        }
      },
      "rsers" => { }
    },
    "oon" => {
      "s" => {
        "quad" => { }
      }
    }
  },
  "loon" => { }
}


=========
DELETION:

If the tree is: (g, goon, goons, goonsquad)
{
  "g" => {
    "oon" => {
      "s" => {
        "quad" => { }
      }
    }
  }
}

And you want to delete "goon",
then the tree should change to: (g, goons, goonsquad)
{
  "g" => {
    "oons" => {
      "quad" => { }
    }
  }
}

But if you want to delete "squad",
then the tree should look like: (g, goon, goons)
{
  "g" => {
    "oon" => {
      "s" => { }
    }
  }
}

=end
