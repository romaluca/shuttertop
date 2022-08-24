alias Shuttertop.Repo
alias Shuttertop.Accounts.User
alias Shuttertop.Contests.Contest
alias Shuttertop.Follows

for _i <- 1..200 do
  contest = Repo.get!(Contest, 1018)
  c = Enum.random(1..2000)
  user = Repo.get!(User, c)
  Follows.add(contest, user)
end
