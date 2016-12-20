
macro comment(str)
    name = gensym("comment")
    :( @doc $str $name = :DOCCOMMENT )
end