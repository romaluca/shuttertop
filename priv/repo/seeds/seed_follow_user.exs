alias Shuttertop.Repo
alias Shuttertop.Accounts.User
alias Shuttertop.Follows

for i <- 1..200 do
  user_to = Repo.get!(User, 1)
  c = Enum.random(1..2000)
  user = Repo.get!(User, c)
  Follows.add(user_to, user)
end
