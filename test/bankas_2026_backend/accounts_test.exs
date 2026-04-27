defmodule Bankas2026Backend.AccountsTest do
  use Bankas2026Backend.DataCase, async: true

  alias Bankas2026Backend.Accounts

  import Bankas2026Backend.AccountsFixtures

  describe "create_user/1" do
    test "creates a user with a normalized username and hashed pin" do
      assert {:ok, user} = Accounts.create_user(%{username: "  GardenR ", pin: "123456"})

      assert user.username == "gardenr"
      assert user.failed_login_attempts == 0
      assert Bcrypt.verify_pass("123456", user.pincode_hash)
    end

    test "rejects duplicate usernames regardless of case" do
      assert {:ok, _user} = Accounts.create_user(%{username: "gardenr", pin: "123456"})

      assert {:error, changeset} = Accounts.create_user(%{username: "GardenR", pin: "654321"})
      assert "has already been taken" in errors_on(changeset).username
    end

    test "rejects invalid pin format" do
      assert {:error, changeset} = Accounts.create_user(%{username: "gardenr", pin: "12345"})
      assert "must be exactly 6 numeric characters" in errors_on(changeset).pin
    end
  end

  describe "update_user/2" do
    test "updates username using the same normalization rules" do
      user = user_fixture()

      assert {:ok, updated_user} = Accounts.update_user(user, %{username: "  NewName "})
      assert updated_user.username == "newname"
    end

    test "rehashes the pin when it changes" do
      user = user_fixture()
      old_hash = user.pincode_hash

      assert {:ok, updated_user} = Accounts.update_user(user, %{pin: "654321"})

      refute updated_user.pincode_hash == old_hash
      assert Bcrypt.verify_pass("654321", updated_user.pincode_hash)
    end

    test "rejects invalid updates and leaves persisted credentials unchanged" do
      user = user_fixture()

      assert {:error, changeset} = Accounts.update_user(user, %{username: "tiny", pin: "abc"})

      persisted_user = Repo.get!(Bankas2026Backend.Accounts.User, user.id)

      assert persisted_user.username == user.username
      assert persisted_user.pincode_hash == user.pincode_hash
      assert "should be at least 6 character(s)" in errors_on(changeset).username
      assert "must be exactly 6 numeric characters" in errors_on(changeset).pin
    end
  end

  describe "authenticate_user/2" do
    test "authenticates valid credentials" do
      user = user_fixture(%{username: "gardenr"})

      assert {:ok, authenticated_user} = Accounts.authenticate_user("gardenr", "123456")
      assert authenticated_user.id == user.id
    end

    test "authenticates usernames case-insensitively" do
      user = user_fixture(%{username: "gardenr"})

      assert {:ok, authenticated_user} = Accounts.authenticate_user("GARDENR", "123456")
      assert authenticated_user.id == user.id
    end

    test "rejects invalid credentials" do
      _user = user_fixture(%{username: "gardenr"})

      assert {:error, :invalid_credentials} = Accounts.authenticate_user("gardenr", "999999")
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("missing", "123456")
    end
  end

  describe "get_user_from_jwt/1" do
    test "returns the user for a valid token" do
      user = user_fixture()
      {:ok, token, _claims} = Bankas2026Backend.Accounts.JWT.create_token(user)

      assert {:ok, authenticated_user} = Accounts.get_user_from_jwt("Bearer " <> token)
      assert authenticated_user.id == user.id
    end

    test "rejects invalid tokens" do
      assert {:error, _reason} = Accounts.get_user_from_jwt("not-a-token")
    end

    test "returns user_not_found for a valid token whose user was deleted" do
      user = user_fixture()
      {:ok, token, _claims} = Bankas2026Backend.Accounts.JWT.create_token(user)
      Repo.delete!(user)

      assert {:error, :user_not_found} = Accounts.get_user_from_jwt(token)
    end
  end
end
