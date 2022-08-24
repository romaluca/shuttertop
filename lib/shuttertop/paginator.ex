defmodule Shuttertop.Paginator do
  @moduledoc """
  Paginate your Ecto queries.

  Instead of using: `Repo.all(query)`, you can use: `Paginator.page(query)`.
  To change the page you can pass the page number as the second argument.

  ## Examples

      iex> Paginator.paginate(query, 1)
      [%Item{id: 1}, %Item{id: 2}, %Item{id: 3}, %Item{id: 4}, %Item{id: 5}]

      iex> Paginator.paginate(query, 2)
      [%Item{id: 6}, %Item{id: 7}, %Item{id: 8}, %Item{id: 9}, %Item{id: 10}]

  """

  require Logger

  import Ecto.Query

  alias Shuttertop.{Page, Repo}

  @page_size 24

  def paginate_with_more(query, opts) do
    final_page_size = opts[:page_size] || @page_size
    page_number = opts[:page] || 1
    results = execute_query(query, page_number, final_page_size, opts)
    count = Enum.count(results)
    more = count == final_page_size
    total_entries = count + (page_number - if(more, do: 0, else: 1)) * final_page_size

    %Page{
      page_number: page_number,
      page_size: final_page_size,
      total_entries: total_entries,
      entries: results,
      more: more
    }
  end

  def paginate(query, opts) do
    final_page_size = opts[:page_size] || @page_size
    page_number = opts[:page] || 1
    results = execute_query(query, page_number, final_page_size, opts)
    total_entries = count_total_results(query)
    total_pages = count_total_pages(total_entries, final_page_size)
    more = total_pages > page_number

    %Page{
      page_number: page_number,
      page_size: final_page_size,
      total_pages: total_pages,
      total_entries: total_entries,
      entries: results,
      more: more
    }
  end

  defp execute_query(query, page_number, page_size, opts) do
    offset = opts[:offset] || page_size * (page_number - 1)

    query
    |> limit(^page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  defp count_total_results(query) do
    query
    |> exclude(:preload)
    |> exclude(:select)
    |> exclude(:order_by)
    |> Repo.aggregate(:count, :id)
  end

  defp count_total_pages(total_results, page_size) do
    total_pages = ceil(total_results / page_size)

    if total_pages > 0, do: total_pages, else: 1
  end
end
