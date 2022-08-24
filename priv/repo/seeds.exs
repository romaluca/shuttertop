# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shuttertop.Repo.insert!(%Shuttertop.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
defmodule Shuttertop.DatabaseSeeder do
  import Ecto.{Query, Changeset}, warn: false
  alias Shuttertop.Repo
  alias Shuttertop.{Contests, Follows, Photos, Posts, Votes}
  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest

  require Logger

  @key_user "topm3rda"

  def insert_user(name, index) do
    user =
      %User{}
      |> User.form_registration_changeset(%{
        name: name,
        authorizations: [
          %{"password" => @key_user, "password_confirmation" => @key_user}
        ],
        email: "fake_#{index}@shuttertop.com"
      })
      |> Ecto.Changeset.cast(%{is_confirmed: true, upload: "U_#{index}.jpg"}, [
        :is_confirmed,
        :upload
      ])
      |> Repo.insert!()

    c = Enum.random(1..30)

    for n <- 1..c do
      try do
        Follows.follow_user(user.id, :create, random_user())
      rescue
        _ -> :rescued
      end
    end
  end

  def delete_user(name) do
    from(u in User, where: u.name == ^name) |> Repo.delete_all()
  end

  defp random_user() do
    from(u in User, order_by: fragment("RANDOM()"), limit: 1) |> Repo.one!()
  end

  defp random_contest() do
    from(u in Contest, order_by: fragment("RANDOM()"), limit: 1) |> Repo.one!()
  end

  def insert_contest(name, index) do
    {:ok, contest} =
      Contests.create_contest(
        %{
          "category_id" => Enum.random(0..8),
          "description" =>
            "Lorem Ipsum è un testo segnaposto utilizzato nel settore della tipografia e della stampa. Lorem Ipsum è considerato il testo segnaposto standard sin dal sedicesimo secolo, quando un anonimo tipografo prese una cassetta di caratteri e li assemblò per preparare un testo campione. È sopravvissuto non solo a più di cinque secoli, ma anche al passaggio alla videoimpaginazione, pervenendoci sostanzialmente inalterato. Fu reso popolare, negli anni ’60, con la diffusione dei fogli di caratteri trasferibili “Letraset”, che contenevano passaggi del Lorem Ipsum, e più recentemente da software di impaginazione come Aldus PageMaker, che includeva versioni del Lorem Ipsum.",
          "expiry_at" => Timex.shift(Timex.today(), days: index + 1) |> Timex.to_datetime(),
          "name" => name
        },
        random_user()
      )

    c = Enum.random(1..30)

    for n <- 1..c do
      try do
        Follows.add(contest, random_user())
      rescue
        _ -> :rescued
      end
    end

    c = Enum.random(1..25)

    for n <- 1..c do
      # try do
      {:ok, %{comment: comment}} =
        Posts.create_comment(
          contest,
          "Lorem #{n} Ipsum è un testo segnaposto utilizzato nel settore della tipografia e della stampa. Lorem Ipsum è considerato il testo segnaposto standard sin dal sedicesimo secolo, quando un anonimo tipografo prese una cassetta di caratteri e li assemblò per preparare un testo campione. È sopravvissuto non solo a più di cinque secoli, ma anche al passaggio alla videoimpaginazione, pervenendoci sostanzialmente inalterato. Fu reso popolare, negli anni ’60, con la diffusione dei fogli di ",
          random_user()
        )

      {:ok, %{comment: comment}} =
        Posts.create_comment(
          contest,
          "Lorem #{(n + 1) * 2} Ipsum è un testo segnaposto",
          random_user()
        )

      # rescue
      #  e ->
      #    Logger.error("ERRORE CREATE COMMENT #{inspect(e)}")
      #    :rescued
      # end
    end

    c = Enum.random(3..32)

    for n <- 1..c do
      # try do
      p = Enum.random(1..104)
      c = Enum.random(1..25)

      {:ok, photo} =
        Photos.create_photo(
          %{"contest_id" => contest.id, "name" => "photo #{p}", "upload" => "P_#{p}.jpg"},
          random_user()
        )

      for n <- 1..c do
        # try do
        {:ok, %{comment: comment}} =
          Posts.create_photo_comment(
            photo.id,
            "Lorem #{n} Ipsum è un testo segnaposto utilizzato nel settore della tipografia e della stampa. Lorem Ipsum è considerato il testo segnaposto standard sin dal sedicesimo secolo, quando un anonimo tipografo prese una cassetta di caratteri e li assemblò per preparare un testo campione. È sopravvissuto non solo a più di cinque secoli, ma anche al passaggio alla videoimpaginazione, pervenendoci sostanzialmente inalterato. Fu reso popolare, negli anni ’60, con la diffusione dei fogli di ",
            random_user()
          )

        {:ok, %{comment: comment}} =
          Posts.create_photo_comment(
            photo.id,
            "Lorem #{(n + 1) * 2} Ipsum è un testo segnaposto",
            random_user()
          )

        # rescue
        #  e ->
        #    Logger.error("ERRORE CREATE COMMENT #{inspect(e)}")
        #    :rescued
        # end
      end

      c = Enum.random(0..30)

      for n <- 1..30 do
        try do
          Votes.add(photo, random_user())
        rescue
          _ -> :rescued
        end
      end

      # rescue
      #  _ -> :rescued
      # end
    end
  end

  def delete_contest(name) do
    from(u in Contest, where: u.name == ^name) |> Repo.delete_all()
  end
end

user_names = [
  "Peppi Pancrazio",
  "Lia Mirabella",
  "Porfirio Nico",
  "Feliciano Gianmarco",
  "Frediano Mariella",
  "Bertoldo Eva",
  "Gianni Manlio",
  "Raoul Fulvio",
  "Luisa Valter",
  "Floro Severo",
  "Aurelio Sisto",
  "Cipriano Elio",
  "Liana Giacobbe",
  "Fortunato Fulvia",
  "Eugenia Manuel",
  "Fiorenzo Dorotea",
  "Amalia Gioia",
  "Giacomo Isotta",
  "Ansaldo Celeste",
  "Camilla Pompeo",
  "Vittore Cosma",
  "Albertina Stefania",
  "Serafino Allegra",
  "Mario Daniela",
  "Oddo Carmine",
  "Olga Raffaele",
  "Fulvio Eligio",
  "Aronne Gavino",
  "Iolanda Gia",
  "Dania Santina",
  "Damiano Marisa"
]

contest_names = [
  "Piedi",
  "Rughe",
  "Trattori",
  "Tubature",
  "Elettrozolla 2011",
  "Festa della limonata",
  "Pini",
  "Vecchi edifici",
  "Terza età",
  "Cipolle",
  "Palloncini",
  "Cani",
  "Areoporti",
  "Facciacce",
  "Rendiconto della vita",
  "Carpooling",
  "La vita che se ne va",
  "Contest molto bello",
  "l'inutilità",
  "Ornitogallo",
  "Goccia",
  "Smeraldo",
  "Radiante",
  "Ricola",
  "Miraggio",
  "Fulmine",
  "Pulce",
  "Calze rotte",
  "Orsacchiotto peloso",
  "Palmipede da competizione",
  "Organetto da strada"
]

for {name, index} <- Enum.with_index(user_names) do
  Shuttertop.DatabaseSeeder.delete_user(name)
  Shuttertop.DatabaseSeeder.insert_user(name, index)
end

for {name, index} <- Enum.with_index(contest_names) do
  Shuttertop.DatabaseSeeder.delete_contest(name)
  Shuttertop.DatabaseSeeder.insert_contest(name, index)
end
