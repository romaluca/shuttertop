defmodule Shuttertop.Page do
  @moduledoc """
  A `Shuttertop.Page` has 5 fields that can be accessed: `entries`, `page_number`, `page_size`, `total_entries` and `total_pages` and `more`.
      page = MyApp.Module.paginate(params)
      page.entries
      page.page_number
      page.page_size
      page.total_entries
      page.total_pages
      page.more
  """

  defstruct [:page_number, :page_size, :total_entries, :total_pages, entries: [], more: false]

  @type t :: %__MODULE__{
          entries: list(),
          page_number: pos_integer(),
          page_size: integer(),
          total_entries: integer(),
          total_pages: pos_integer(),
          more: boolean()
        }

  defimpl Enumerable do
    @spec count(Shuttertop.Page.t()) :: {:error, Enumerable.Shuttertop.Page}
    def count(_page), do: {:error, __MODULE__}

    @spec member?(Shuttertop.Page.t(), term) :: {:error, Enumerable.Shuttertop.Page}
    def member?(_page, _value), do: {:error, __MODULE__}

    @spec reduce(Shuttertop.Page.t(), Enumerable.acc(), Enumerable.reducer()) ::
            Enumerable.result()
    def reduce(%Shuttertop.Page{entries: entries}, acc, fun) do
      Enumerable.reduce(entries, acc, fun)
    end

    @spec slice(Shuttertop.Page.t()) :: {:error, Enumerable.Shuttertop.Page}
    def slice(_page), do: {:error, __MODULE__}
  end

  defimpl Collectable do
    @spec into(Shuttertop.Page.t()) ::
            {term, (term, Collectable.command() -> Shuttertop.Page.t() | term)}
    def into(original) do
      original_entries = original.entries
      impl = Collectable.impl_for(original_entries)
      {_, entries_fun} = impl.into(original_entries)

      fun = fn page, command ->
        %{page | entries: entries_fun.(page.entries, command)}
      end

      {original, fun}
    end
  end
end
