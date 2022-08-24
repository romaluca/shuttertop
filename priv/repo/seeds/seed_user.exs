alias Shuttertop.Repo
alias Shuttertop.Accounts.User
alias Shuttertop.Contests.Contest
alias Shuttertop.Photos
users = 2000

for i <- 1..users do
  contests = 1000
  c = Enum.random(1..contests)
  contest = Repo.get!(Contest, c)
  user = Repo.get!(User, 1)
  img = Enum.random(1..104)

  {:ok, photo} =
    Photos.create_photo(
      %{"contest_id" => contest.id, "name" => "photo", "upload" => "P_#{img}.jpg"},
      user
    )
end
