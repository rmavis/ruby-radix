# For this tree, each node is a three-item array:
# 1. a string
# 2. a symbol (if the string is part of a valid word branch) or nil
#    (if not)
# 3. the children
# The children will be an array of arrays, each of which will be a
# three-item array following this format.


class RadixTree


  def initialize
    @store = [ ]
  end


  def add( string, func = nil )
    func = string.to_sym if func.nil?
    puts "Adding '#{string}'."
    @store = add_to_nodes(@store, string, func)
    puts "Store: #{@store}"
  end


  def get( string )
    puts "Searching tree for '#{string}'."
    has = get_from_nodes(@store, string)
    puts "Has? '#{has}'"
  end


  def del( string )
    puts "Removing '#{string}' from store."
    @store = remove_from_nodes(@store, string)
    puts "Store: #{@store}"
  end





  protected


  def add_to_nodes( nodes, string, func )
    new_nodes = [ ]
    unrelated = true
    string_len = string.length

    (0..nodes.length).each do |n|
      if node = nodes[n]
        trunk = node[0]
        trunk_len = trunk.length
        simdex = string.simdex(trunk)

        if simdex > 0
          unrelated = nil

          # `trunk` is a substring of `string`, eg `abc` given `abcde`.
          if (simdex == trunk_len)
            if (simdex < string_len)
              node = add_to_node(node, string.leaf(simdex), func)
            # This allows for easy updating of a node's func.
            elsif (node[1] != func)
              node = [node[0], func, node[2]]
            end

          # `string` is a substring of `trunk`, eg `abcde` given `abc`.
          elsif ((simdex == string_len) && (simdex < trunk_len))
            old_nodes = [ [trunk.leaf(simdex), node[1], node[2]] ]
            node = [ string, func, old_nodes ]

          # `string` and `trunk` share a base but diverge.
          elsif ((simdex < string_len) && (simdex < trunk_len))
            old_nodes = [ [trunk.leaf(simdex), node[1], node[2]],
                          [string.leaf(simdex), func, [ ]] ]
            node = [trunk[0, simdex], nil, old_nodes]
          end
        end

        new_nodes.push(node)
      end
    end

    # This is the case when the string is unrelated.
    # e.g. 'abc' branch given 'cba'.
    new_nodes.push([string, func, [ ]]) if unrelated

    return new_nodes
  end



  # The node passed to this must be well-formed, meaning an array
  # containing three elements:
  # 1. A string (must not be empty)
  # 2. A symbol (may be nil)
  # 3. An array
  def add_to_node( node, string, func )
    if string.empty?
      puts "No string to add."

    elsif node[2].empty?
      # puts "Adding #{string}/#{func} to empty children of node '#{node[0]}'."
      node[2] = node[2].push([string, func, [ ]])

    else
      node[2] = add_to_nodes(node[2], string, func)
    end

    return node
  end



  # This function will return the [1]st part of a node. If that
  # value is nil, then the word is not part of a valid chain. Else,
  # is.
  def get_from_nodes(nodes, string)
    string_len = string.length

    (0..nodes.length).each do |n|
      if node = nodes[n]
        trunk = node[0]
        trunk_len = trunk.length
        simdex = string.simdex(trunk)

        # if simdex > 0
        if simdex == trunk_len
          if simdex < string_len
            return get_from_nodes(node[2], string.leaf(simdex))
          else
            return node[1]
          end
        end
        # end
      end
    end

    return nil
  end



  # If the [1]st part of a node is nil, then the [0]th part is not
  # part of a calid word chain. But that word part might still be
  # needed to form words later in the branch, because removing it
  # would introduce much redundancy in the word parts. So a node
  # will only be removed if it is a leaf, else its [1]st part will
  # be made nil.
  def remove_from_nodes( nodes, string )
    new_nodes = [ ]
    string_len = string.length

    (0..nodes.length).each do |n|
      keep = true

      if node = nodes[n]
        trunk = node[0]
        trunk_len = trunk.length
        simdex = string.simdex(trunk)

        if simdex > 0
          if simdex == trunk_len
            if simdex == string_len
              if node[2].empty?
                keep = nil
              else
                node = [ node[0], nil, node[2] ]
              end

            else
              node = [
                node[0],
                node[1],
                remove_from_nodes(node[2], string.leaf(simdex))
              ]
            end
          end
        end

        new_nodes.push(node) if keep
      end
    end

    return new_nodes
  end


end







#
# Helper functions.
#

class String

  # SIMilarity inDEX. ha.
  # Pass this a string. Starting at the beginning, it will compare
  # that string letter by letter with self and increment a counter
  # while the letters are the same.
  # The simdex will never be greater than the length of either of
  # the strings.
  # If the simdex is equal to the length of self and less than the
  # length of the parameter, then self is a substring of the
  # parameter.
  #   abc.simdex('abcd') == 3
  # If the simdex is equal to the length of the parameter and less
  # than the length of self, then the parameter is a substring of
  # self.
  #   abcd.simdex('abc') == 3
  # If the simdex is less than the lengths of both the parameter and
  # self, then the two share a base but diverge.
  #   abcde.simdex('abced') == 3
  # If the simdex is equal to the lengths of self and the parameter,
  # then they are identical.
  #   abc.simdex('abc') == 3
  # If the simdex is 0, then the 0th characters are not common.
  #   abcde.simdex('edcba') == 0
  def simdex( str )
    s = 0
    s += 1 while ((self[s]) && (self[s] == str[s]))
    return s
  end


  def leaf( n )
    return self[n, (self.length - n)]
  end

end




rad = RadixTree.new

rad.add('groupies')
rad.add('groupie')
rad.add('group')
rad.add('grouper')
rad.add('grouper')
rad.add('grouper')
rad.add('farts')
rad.add('fartso')
rad.add('farty')  # This one splits the fart branch on `fart`
rad.add('fartsalot')
rad.add('fartsalsa')

rad.get('groupies')
rad.get('farts')
rad.get('start')

rad.del('groupie')
rad.del('farty')
rad.del('ooo')

rad.add('groupies', :whatitdo)
rad.add('fart', :fartfart)
rad.get('groupies')
rad.get('fart')



=begin
[
  [
    "group",
    :group,
    [
      [
        "ie",
        :groupie,
        [
          [
            "s",
            :groupies,
            []
          ]
        ]
      ],
      [
        "er",
        :grouper,
        []
      ]
    ]
  ],
  [
    "fart",
    nil,
    [
      [
        "s",
        :farts,
        [
          [
            "o",
            :fartso,
            []
          ],
          [
            "a",
            :fartsa,
            [
              [
                "lot",
                :fartsalot,
                []
              ]
            ]
          ]
        ]
      ],
      [
        "y",
        :farty,
        []
      ]
    ]
  ]
]
=end
