### Abstract parameter IOStreams

abstract ParameterIOStream{S<:ValueSupport} <: VariableIOStream

### BasicContParamIOStream

type BasicContParamIOStream <: ParameterIOStream{Continuous}
  value::Union{IOStream, Void}
  loglikelihood::Union{IOStream, Void}
  logprior::Union{IOStream, Void}
  logtarget::Union{IOStream, Void}
  gradloglikelihood::Union{IOStream, Void}
  gradlogprior::Union{IOStream, Void}
  gradlogtarget::Union{IOStream, Void}
  tensorloglikelihood::Union{IOStream, Void}
  tensorlogprior::Union{IOStream, Void}
  tensorlogtarget::Union{IOStream, Void}
  dtensorloglikelihood::Union{IOStream, Void}
  dtensorlogprior::Union{IOStream, Void}
  dtensorlogtarget::Union{IOStream, Void}
  diagnosticvalues::Union{IOStream, Void}
  names::Vector{AbstractString}
  size::Tuple
  n::Int
  diagnostickeys::Vector{Symbol}
  open::Function
  close::Function
  mark::Function
  reset::Function
  flush::Function
  write::Function

  function BasicContParamIOStream(
    size::Tuple,
    n::Int,
    streams::Vector{Union{IOStream, Void}},
    diagnostickeys::Vector{Symbol}=Symbol[],
    filenames::Vector{AbstractString}=[(streams[i] == nothing) ? "" : streams[i].name[7:end-1] for i in 1:14]
  )
    instance = new()

    fnames = fieldnames(BasicContParamIOStream)
    for i in 1:14
      setfield!(instance, fnames[i], streams[i])
    end

    instance.names = filenames

    instance.size = size
    instance.n = n
    instance.diagnostickeys = diagnostickeys

    instance.open = eval(codegen_open_basiccontparamiostream(instance, fnames))
    instance.close = eval(codegen_close_basiccontparamiostream(instance, fnames))
    instance.mark = eval(codegen_mark_basiccontparamiostream(instance, fnames))
    instance.reset = eval(codegen_reset_basiccontparamiostream(instance, fnames))
    instance.flush = eval(codegen_flush_basiccontparamiostream(instance, fnames))
    instance.write = eval(codegen_write_basiccontparamiostream(instance, fnames))

    instance
  end
end

function BasicContParamIOStream(
  size::Tuple,
  n::Int,
  filenames::Vector{AbstractString},
  diagnostickeys::Vector{Symbol}=Symbol[],
  mode::AbstractString="w"
)
  fnames = fieldnames(BasicContParamIOStream)
  BasicContParamIOStream(
    size,
    n,
    [isempty(filenames[i]) ? nothing : open(filenames[i], mode) for i in 1:14],
    diagnostickeys,
    filenames
  )
end

function BasicContParamIOStream(
  size::Tuple,
  n::Int;
  monitor::Vector{Bool}=[true; fill(false, 12)],
  filepath::AbstractString="",
  filesuffix::AbstractString="csv",
  diagnostickeys::Vector{Symbol}=Symbol[],
  mode::AbstractString="w"
)
  fnames = fieldnames(BasicContParamIOStream)

  filenames = Array(AbstractString, 14)
  for i in 1:13
    filenames[i] = (monitor[i] == false ? "" : joinpath(filepath, string(fnames[i])*"."*filesuffix))
  end
  filenames[14] = (isempty(diagnostickeys) ? "" : joinpath(filepath, "diagnosticvalues."*filesuffix))

  BasicContParamIOStream(size, n, filenames, diagnostickeys, mode)
end

function BasicContParamIOStream(
  size::Tuple,
  n::Int,
  monitor::Vector{Symbol};
  filepath::AbstractString="",
  filesuffix::AbstractString="csv",
  diagnostickeys::Vector{Symbol}=Symbol[],
  mode::AbstractString="w"
)
  fnames = fieldnames(BasicContParamIOStream)
  BasicContParamIOStream(
    size,
    n,
    monitor=[fnames[i] in monitor ? true : false for i in 1:13],
    filepath=filepath,
    filesuffix=filesuffix,
    diagnostickeys=diagnostickeys,
    mode=mode
  )
end

function codegen_close_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(body, :(close(getfield($(iostream), $(QuoteNode(f))))))
    end
  end

  @gensym close_basiccontparamiostream

  quote
    function $close_basiccontparamiostream()
      $(body...)
    end
  end
end

function codegen_open_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol

  push!(body,:($(iostream).names = _names))

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(body, :(setfield!($(iostream), $(QuoteNode(f)), open(_names[$i], _mode))))
    end
  end

  @gensym open_basiccontparamiostream

  quote
    function $open_basiccontparamiostream{S<:AbstractString}(_names::Vector{S}, _mode::AbstractString="w")
      $(body...)
    end
  end
end

function codegen_mark_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(body, :(mark(getfield($(iostream), $(QuoteNode(f))))))
    end
  end

  @gensym mark_basiccontparamiostream

  quote
    function $mark_basiccontparamiostream()
      $(body...)
    end
  end
end

function codegen_reset_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(body, :(reset(getfield($(iostream), $(QuoteNode(f))))))
    end
  end

  @gensym reset_basiccontparamiostream

  quote
    function $reset_basiccontparamiostream()
      $(body...)
    end
  end
end

function codegen_flush_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(body, :(flush(getfield($(iostream), $(QuoteNode(f))))))
    end
  end

  @gensym flush_basiccontparamiostream

  quote
    function $flush_basiccontparamiostream()
      $(body...)
    end
  end
end

# To visually inspect code generation via codegen_write_basiccontparamiostream, try for example
# using Lora
#
# iostream = BasicContParamIOStream((), 4, filepath="", mode="w")
# Lora.codegen_write_basiccontparamiostream(iostream, fieldnames(BasicContParamIOStream))
# close(iostream)

function codegen_write_basiccontparamiostream(iostream::BasicContParamIOStream, fnames::Vector{Symbol})
  body = []
  local f::Symbol # f must be local to avoid compiler errors. Alternatively, this variable declaration can be omitted

  for i in 1:14
    if iostream.(fnames[i]) != nothing
      f = fnames[i]
      push!(
        body,
        :(write(getfield($(iostream), $(QuoteNode(f))), join(getfield(_state, $(QuoteNode(f))), ','), "\n"))
      )
    end
  end

  @gensym write_basiccontparamiostream

  quote
    function $write_basiccontparamiostream{F<:VariateForm}(_state::ParameterState{Continuous, F})
      $(body...)
    end
  end
end

function Base.write(iostream::BasicContParamIOStream, nstate::BasicContUnvParameterNState)
  fnames = fieldnames(BasicContParamIOStream)
  for i in 1:13
    if iostream.(fnames[i]) != nothing
      writedlm(iostream.(fnames[i]), nstate.(fnames[i]))
    end
  end
  if iostream.diagnosticvalues != nothing
    writedlm(iostream.diagnosticvalues, nstate.diagnosticvalues', ',')
  end
end

function Base.write(iostream::BasicContParamIOStream, nstate::BasicContMuvParameterNState)
  fnames = fieldnames(BasicContParamIOStream)
  for i in 2:4
    if iostream.(fnames[i]) != nothing
      writedlm(iostream.(fnames[i]), nstate.(fnames[i]))
    end
  end
  for i in (1, 5, 6, 7, 14)
    if iostream.(fnames[i]) != nothing
      writedlm(iostream.(fnames[i]), nstate.(fnames[i])', ',')
    end
  end
  for i in 8:10
    if iostream.(fnames[i]) != nothing
      statelen = abs2(iostream.size)
      for i in 1:nstate.n
        write(iostream.stream, join(nstate.value[1+(i-1)*statelen:i*statelen], ','), "\n")
      end
    end
  end
  for i in 11:13
    if iostream.(fnames[i]) != nothing
      statelen = iostream.size^3
      for i in 1:nstate.n
        write(iostream.stream, join(nstate.value[1+(i-1)*statelen:i*statelen], ','), "\n")
      end
    end
  end
end

function Base.read!{N<:Real}(iostream::BasicContParamIOStream, nstate::BasicContUnvParameterNState{N})
  fnames = fieldnames(BasicContParamIOStream)
  for i in 1:13
    if iostream.(fnames[i]) != nothing
      setfield!(nstate, fnames[i], vec(readdlm(iostream.(fnames[i]), ',', N)))
    end
  end
  if iostream.diagnosticvalues != nothing
    nstate.diagnosticvalues = readdlm(iostream.diagnosticvalues, ',', Any)'
  end
end

function Base.read!{N<:Real}(iostream::BasicContParamIOStream, nstate::BasicContMuvParameterNState{N})
  fnames = fieldnames(BasicContParamIOStream)
  for i in 2:4
    if iostream.(fnames[i]) != nothing
      setfield!(nstate, fnames[i], vec(readdlm(iostream.(fnames[i]), ',', N)))
    end
  end
  for i in (1, 5, 6, 7)
    if iostream.(fnames[i]) != nothing
      setfield!(nstate, fnames[i], readdlm(iostream.(fnames[i]), ',', N)')
    end
  end
  for i in 8:10
    if iostream.(fnames[i]) != nothing
      statelen = abs2(iostream.size)
      line = 1
      while !eof(iostream.stream)
        nstate.value[1+(line-1)*statelen:line*statelen] =
          [parse(N, c) for c in split(chomp(readline(iostream.stream)), ',')]
        line += 1
      end
    end
  end
  for i in 11:13
    if iostream.(fnames[i]) != nothing
      statelen = iostream.size^3
      line = 1
      while !eof(iostream.stream)
        nstate.value[1+(line-1)*statelen:line*statelen] =
          [parse(N, c) for c in split(chomp(readline(iostream.stream)), ',')]
        line += 1
      end
    end
  end
  if iostream.diagnosticvalues != nothing
    nstate.diagnosticvalues = readdlm(iostream.diagnosticvalues, ',', Any)'
  end
end

function Base.read{N<:Real}(iostream::BasicContParamIOStream, T::Type{N})
  nstate::Union{ParameterNState{Continuous, Univariate}, ParameterNState{Continuous, Multivariate}}
  fnames = fieldnames(BasicContParamIOStream)
  l = length(iostream.size)

  if l == 0
    nstate = BasicContUnvParameterNState(
      iostream.n,
      [iostream.(fnames[i]) != nothing ? true : false for i in 1:13],
      iostream.diagnostickeys,
      T
    )
  elseif l == 1
    nstate = BasicContMuvParameterNState(
      iostream.size[1],
      iostream.n,
      [iostream.(fnames[i]) != nothing ? true : false for i in 1:13],
      iostream.diagnostickeys,
      T
    )
  else
    error("BasicVariableIOStream.size must be a tuple of length 0 or 1, got $(iostream.size) length")
  end

  read!(iostream, nstate)

  nstate
end
