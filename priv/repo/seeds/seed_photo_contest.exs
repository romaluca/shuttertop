alias Shuttertop.Repo
alias Shuttertop.Accounts.User
alias Shuttertop.Contests.Contest
alias Shuttertop.Photos
users = 2000

for _i <- 1..users do
  contest = Repo.get!(Contest, 1018)
  c = Enum.random(1..2000)
  user = Repo.get!(User, c)
  img = Enum.random(1..104)

  {:ok, _} =
    Photos.create_photo(
      %{"contest_id" => contest.id, "name" => "photo", "upload" => "P_#{img}.jpg"},
      user
    )
end
